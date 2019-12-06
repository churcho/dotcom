defmodule SiteWeb.ScheduleController.FinderApi do
  @moduledoc """
    API for retrieving journeys for a route, and for
    showing trip details for each journey.
  """
  use SiteWeb, :controller

  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.Schedule
  alias SiteWeb.ScheduleController.TripInfo, as: Trips
  alias SiteWeb.ScheduleController.VehicleLocations, as: Vehicles

  import SiteWeb.ScheduleController.ScheduleApi, only: [format_time: 1, fares_for_service: 4]

  @type react_keys :: :date | :direction | :is_current
  @type react_strings :: [{react_keys, String.t()}]
  @type converted_values :: {Date.t(), integer, boolean}

  # Leverage the JourneyList module to return a simplified set of trips
  @spec journeys(Plug.Conn.t(), map) :: Plug.Conn.t()
  def journeys(conn, %{"stop" => stop_id} = params) do
    {schedules, predictions} = load_from_repos(conn, params)

    journey_opts = [
      origin_id: stop_id,
      destination_id: nil,
      current_time: nil
    ]

    journeys =
      schedules
      |> JourneyList.build(predictions, :predictions_then_schedules, true, journey_opts)
      |> prepare_journeys_for_json()

    json(conn, journeys)
  end

  # Use alternative JourneyList constructor to only return trips with predictions
  @spec departures(Plug.Conn.t(), map) :: Plug.Conn.t()
  def departures(conn, %{"stop" => stop_id} = params) do
    {schedules, predictions} = load_from_repos(conn, params)

    journeys =
      schedules
      |> JourneyList.build_predictions_only(predictions, stop_id, nil)
      |> prepare_journeys_for_json()

    json(conn, journeys)
  end

  # Return a modified %TripInfo{} map by building up the conn.
  # Simulates the :trip_info data generated by the schedules/x/schedule tab
  @spec trip(Plug.Conn.t(), map) :: Plug.Conn.t()
  def trip(conn, %{
        "id" => trip_id,
        "route" => route_id,
        "date" => date,
        "direction" => direction,
        "stop" => origin
      }) do
    {service_end_date, direction_id, _} = convert_from_string(date: date, direction: direction)

    route = Routes.Repo.get(route_id)
    opts = Map.get(conn.assigns, :trip_info_functions, [])

    trip_info =
      conn
      |> assign(:date, service_end_date)
      |> assign(:direction_id, direction_id)
      |> assign(:origin, origin)
      |> assign(:route, route)
      |> Map.put(:query_params, %{"trip" => trip_id})
      |> Vehicles.call(Vehicles.init([]))
      |> Trips.call(Trips.init(opts))
      |> Map.get(:assigns)
      |> Map.get(:trip_info)
      |> json_safe_trip_info()
      |> update_in([:times], &simplify_time/1)
      |> add_computed_fares_to_trip_info(trip_id, route)
      |> trim_schedule_stops(origin)

    json(conn, trip_info)
  end

  # Use internal API to generate list of relevant schedules and predictions
  @spec load_from_repos(Plug.Conn.t(), map) :: {[Schedule.t()], [Prediction.t()]}
  defp load_from_repos(conn, %{
         "id" => route_id,
         "date" => date,
         "direction" => direction,
         "stop" => stop_id,
         "is_current" => is_current
       }) do
    {service_end_date, direction_id, current_service?} =
      convert_from_string(date: date, direction: direction, is_current: is_current)

    # JourneyList orders trips according to their prediction time first (if present),
    # and then by scheduled time. If the selcted service is valid for the current day,
    # request schedules for the current day instead of the service end date, so that the
    # schedule date matches the prediction dates, thereby keeping trips in time order.
    current_date = DateTime.to_date(conn.assigns.date_time)
    schedule_date = if current_service?, do: current_date, else: service_end_date

    schedule_opts = [date: schedule_date, direction_id: direction_id, stop_ids: [stop_id]]
    schedules_fn = Map.get(conn.assigns, :schedules_fn, &Schedules.Repo.by_route_ids/2)
    schedules = schedules_fn.([route_id], schedule_opts)

    prediction_opts = [route: route_id, stop: stop_id, direction_id: direction_id]
    predictions_fn = Map.get(conn.assigns, :predictions_fn, &Predictions.Repo.all/1)
    predictions = if current_service?, do: predictions_fn.(prediction_opts), else: []

    {schedules, predictions}
  end

  @spec prepare_journeys_for_json(JourneyList.t()) :: [map]
  defp prepare_journeys_for_json(journey_list) do
    journey_list
    |> Map.get(:journeys)
    |> Enum.map(&destruct_journey/1)
    |> Enum.map(&lift_up_route/1)
    |> Enum.map(&set_departure_time/1)
    |> Enum.map(&json_safe_journey/1)
  end

  # Break down structs in order to use Access functions
  @spec destruct_journey(Journey.t()) :: map
  defp destruct_journey(journey) do
    journey
    |> Map.from_struct()
    |> update_in([:departure], &Map.from_struct/1)
    |> update_in([:departure, :schedule], &maybe_destruct_element/1)
    |> update_in([:departure, :prediction], &maybe_destruct_element/1)
  end

  # Convert non-binary parameter values into expected formats
  @spec convert_from_string(react_strings) :: converted_values
  defp convert_from_string(params) do
    {:ok, date} =
      params
      |> Keyword.get(:date)
      |> Date.from_iso8601()

    direction_id =
      params
      |> Keyword.get(:direction)
      |> String.to_integer()

    current_service? = Keyword.get(params, :is_current) === "true"

    {date, direction_id, current_service?}
  end

  # Move a representational %Route{} for this journey up to the top level
  # prior to removing from all child elements (redundant/unused by client)
  # Schedule may be nil, in which case, get the route from Prediction
  @spec lift_up_route(map) :: map
  defp lift_up_route(%{departure: %{schedule: %{route: route}}} = journey) do
    put_route(journey, route)
  end

  defp lift_up_route(%{departure: %{prediction: %{route: route}}} = journey) do
    put_route(journey, route)
  end

  defp put_route(journey, route) do
    Map.put_new(journey, :route, Route.to_json_safe(route))
  end

  # Check for predictions w/o a schedule (added in predictions)
  # If there's a prediction and a schedule, use the schedule time
  defp set_departure_time(%{departure: departure} = journey) do
    departure_time =
      case departure do
        %{schedule: nil, prediction: p} -> p.time
        %{schedule: s, prediction: _} -> s.time
      end

    update_in(journey, [:departure], &Map.put_new(&1, :time, format_time(departure_time)))
  end

  # Removes problematic/unnecessary data from JSON response:
  # - Journeys' nested %Stop{} data is unused by client and contains integer keys
  # - Removes nested %Route{} and %Trip{} data as it is redundant
  # - Drops :arrival key from %Journey{}
  @spec json_safe_journey(map) :: map
  defp json_safe_journey(%{departure: departure} = journey) do
    clean_schedule_and_prediction =
      departure
      |> clean_schedule_or_prediction(:schedule)
      |> clean_schedule_or_prediction(:prediction)
      |> update_in([:schedule], &maybe_nil_schedule_stop/1)
      |> update_in([:prediction], &maybe_remove_prediction_stop/1)

    journey
    |> Map.drop([:arrival])
    |> Map.put(:departure, clean_schedule_and_prediction)
  end

  # Removes problematic/unnecessary data from JSON response:
  # - Drops :route and :trip from each schedule/prediction (redundant)
  @spec json_safe_trip_info(TripInfo.t()) :: map
  defp json_safe_trip_info(trip_info) do
    clean_schedules_and_predictions =
      trip_info.times
      |> Enum.map(&Map.from_struct/1)
      |> Enum.map(&clean_schedule_or_prediction(&1, :schedule))
      |> Enum.map(&clean_schedule_or_prediction(&1, :prediction))

    trip_info
    |> Map.from_struct()
    |> Map.drop([:route, :base_fare])
    |> Map.put(:times, clean_schedules_and_predictions)
  end

  defp clean_schedule_or_prediction(%{prediction: nil} = no_prediction, :prediction) do
    no_prediction
  end

  defp clean_schedule_or_prediction(%{schedule: nil} = no_schedule, :schedule) do
    no_schedule
  end

  defp clean_schedule_or_prediction(schedule_or_prediction, key) do
    update_in(schedule_or_prediction, [key], &Map.drop(&1, [:route, :trip]))
  end

  defp add_computed_fares_to_trip_info(trip_info, trip_id, route) do
    fare_params = %{
      trip: trip_id,
      route: route,
      origin: trip_info.origin_id,
      destination: trip_info.destination_id
    }

    trip_info
    |> Map.put(:times, Enum.map(trip_info.times, &add_computed_fare(&1, fare_params)))
    |> add_computed_fare(fare_params)
  end

  defp add_computed_fare(%{schedule: %{stop: %{id: id}}} = container, fare_params) do
    update_in(
      container,
      [:schedule],
      &Map.put(&1, :fare, compute_fare(%{fare_params | destination: id}))
    )
  end

  defp add_computed_fare(%{prediction: _} = no_fare_for_prediction, _) do
    no_fare_for_prediction
  end

  defp add_computed_fare(container, fare_params) do
    Map.put(container, :fare, compute_fare(fare_params))
  end

  # Given params, generate a fare for a particular trip and/or origin/destination
  defp compute_fare(fare_params) do
    fares_for_service(
      fare_params.route,
      fare_params.trip,
      fare_params.origin,
      fare_params.destination
    )
  end

  # Only show times beginning at the selected origin stop onward
  defp trim_schedule_stops(%{times: times} = trip_info, stop_id) do
    trimmed_times =
      Enum.drop_while(times, fn time = time ->
        time.schedule && time.schedule.stop && time.schedule.stop.id !== stop_id
      end)

    Map.put(trip_info, :times, trimmed_times)
  end

  # Converts a DateTime to a simple string
  defp simplify_time(schedules_and_predictions) do
    Enum.map(
      schedules_and_predictions,
      fn schedule_and_prediction ->
        schedule_and_prediction
        |> update_in([:schedule], &maybe_format_element_time/1)
        |> update_in([:prediction], &maybe_format_element_time/1)
      end
    )
  end

  # Schedule or Prediction may be nil. If not, convert struct to map.
  @spec maybe_destruct_element(Schedule.t() | Prediction.t() | nil) :: map | nil
  defp maybe_destruct_element(nil), do: nil
  defp maybe_destruct_element(el), do: Map.from_struct(el)

  # Schedule may be nil
  @spec maybe_nil_schedule_stop(map | nil) :: map
  defp maybe_nil_schedule_stop(nil), do: nil
  defp maybe_nil_schedule_stop(schedule), do: Map.put(schedule, :stop, nil)

  # A prediction time is nil for the last stop of a trip.
  # Schedule or Prediction itself may be nil however
  @spec maybe_format_element_time(map | nil) :: map | nil
  defp maybe_format_element_time(nil), do: nil
  defp maybe_format_element_time(%{time: nil} = el), do: el
  defp maybe_format_element_time(%{time: time} = el), do: %{el | time: format_time(time)}

  # Prediction may be nil
  @spec maybe_remove_prediction_stop(map | nil) :: map | nil
  defp maybe_remove_prediction_stop(nil), do: nil
  defp maybe_remove_prediction_stop(p), do: Map.put(p, :stop, nil)
end
