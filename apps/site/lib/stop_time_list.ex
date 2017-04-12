defmodule StopTimeList do
  @moduledoc """
  Responsible for grouping together schedules and predictions based on an origin and destination, in
  a form to be used in the schedule views.
  """

  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}

  defstruct [
    times: [],
    expansion: :none
  ]
  @type t :: %__MODULE__{
    times: [StopTime.t],
    expansion: :expanded | :collapsed | :none
  }
  @type stop_id :: String.t
  @type schedule_pair :: PredictedSchedule.Group.schedule_pair_t
  @type map_key_t :: PredictedSchedule.Group.map_key_t
  @type schedule_map :: %{map_key_t => %{stop_id => Schedule.t}}
  @type schedule_pair_map :: %{map_key_t => schedule_pair}

  @doc "Returns true if any of the stop times have a prediction"
  @spec has_predictions?(t) :: boolean
  def has_predictions?(%StopTimeList{times: times}) do
    times
    |> Enum.any?(&StopTime.has_prediction?/1)
  end

  @doc """
  Builds a StopTimeList from given schedules and predictions.
  schedules: Schedules to be combined with predictions for StopTimes
  predictions: Predictions to combined with schedules for StopTimes
  origin_id (optional): Trip origin
  destination_id (optional): Trip Destination
  filter_flag: Flag to determine how the trip list will be filtered and sorted
  current_time (optional): Current time, used to determine the first trip to in filtered/sorted list. If nil, all trips will be returned
  keep_all?: Determines if all stop times should be returned, regardless of filter flag
  """
  @spec build([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil, StopTime.Filter.filter_flag_t, DateTime.t | nil, boolean) :: __MODULE__.t
  def build(schedules, predictions, origin_id, destination_id, filter_flag, current_time, keep_all?) do
    schedules
    |> build_times(predictions, origin_id, destination_id)
    |> from_times(filter_flag, current_time, keep_all?)
  end

  @doc """
  Build a StopTimeList using only predictions. This will also filter out predictions that are
  missing departure_predictions. Limits to 5 predictions at most.
  """
  @spec build_predictions_only([Schedule.t], [Prediction.t], String.t | nil, String.t | nil) :: __MODULE__.t
  def build_predictions_only(schedules, predictions, origin_id, destination_id) do
    stop_time = schedules
    |> build_times(predictions, origin_id, destination_id)
    |> Enum.filter(&StopTime.has_departure_prediction?/1)
    |> from_times(:keep_all, nil, true)
    %{stop_time | times: Enum.take(stop_time.times, 5)}
  end

  @spec build_times([Schedule.t | schedule_pair], [Prediction.t], String.t | nil, String.t | nil) :: [StopTime.t]
  defp build_times(schedule_pairs, predictions, origin_id, destination_id) when is_binary(origin_id) and is_binary(destination_id) do
    predictions = match_schedule_direction(schedule_pairs, predictions)
    stop_times = group_trips(
      schedule_pairs,
      predictions,
      origin_id,
      destination_id,
      &build_schedule_pair_map/2,
      &build_stop_time(&1, &2, &3, origin_id, destination_id)
    )
    Enum.reject(stop_times, &reversed_stop_time?/1)
  end
  defp build_times(schedules, predictions, origin_id, nil) when is_binary(origin_id) do
    group_trips(
      schedules,
      predictions,
      origin_id,
      nil,
      &build_schedule_map/2,
      &predicted_departures(&1, &2, &3, origin_id)
    )
  end
  defp build_times(_schedules, _predictions, _origin_id, _destination_id), do: []

  # Creates a StopTimeList object from a list of times and the expansion value
  # Both the expanded and collapsed times are calculated in order to determine the `expansion` field
  @spec from_times([StopTime.t], StopTime.Filter.filter_flag_t, DateTime.t | nil, boolean) :: __MODULE__.t
  defp from_times(expanded_times, filter_flag, current_time, keep_all?) do
    collapsed_times = expanded_times
    |> StopTime.Filter.filter(filter_flag, current_time)
    |> StopTime.Filter.sort
    |> StopTime.Filter.limit(!keep_all?)

    %__MODULE__{
      times: (if keep_all?, do: StopTime.Filter.sort(expanded_times), else: collapsed_times),
      expansion: StopTime.Filter.expansion(expanded_times, collapsed_times, keep_all?)
    }
  end

  defp group_trips(schedules, predictions, origin_id, destination_id, build_schedule_map_fn, trip_mapper_fn) do
    prediction_map = PredictedSchedule.Group.build_prediction_map(predictions, schedules, origin_id, destination_id)
    schedule_map = Enum.reduce(schedules, %{}, build_schedule_map_fn)

    schedule_map
    |> get_trips(prediction_map)
    |> Enum.map(&(trip_mapper_fn.(&1, schedule_map, prediction_map)))
  end

  @spec build_stop_time(map_key_t, schedule_pair_map, PredictedSchedule.Group.prediction_map_t, stop_id, stop_id) :: StopTime.t
  defp build_stop_time(key, schedule_map, prediction_map, origin_id, dest) do
    departure_prediction = prediction_map[key][origin_id]
    arrival_prediction = prediction_map[key][dest]
    case Map.get(schedule_map, key) do
      {departure, arrival} ->
        trip = first_trip([departure_prediction, departure, arrival_prediction, arrival])

        %StopTime{
          departure: %PredictedSchedule{schedule: departure, prediction: departure_prediction},
          arrival: %PredictedSchedule{schedule: arrival, prediction: arrival_prediction},
          trip: trip
        }
      nil ->
        trip = first_trip([departure_prediction, arrival_prediction])
        %StopTime{
          departure: %PredictedSchedule{schedule: nil, prediction: departure_prediction},
          arrival: %PredictedSchedule{schedule: nil, prediction: arrival_prediction},
          trip: trip
        }
    end
  end

  @spec predicted_departures(map_key_t, schedule_map, PredictedSchedule.Group.prediction_map_t, stop_id) :: StopTime.t
  defp predicted_departures(key, schedule_map, prediction_map, origin_id) do
    departure_schedule = schedule_map[key][origin_id]
    departure_prediction = prediction_map[key][origin_id]
    %StopTime{
      departure: %PredictedSchedule{schedule: departure_schedule, prediction: departure_prediction},
      arrival: nil,
      trip: first_trip([departure_prediction, departure_schedule])
    }
  end

  @spec get_trips(schedule_pair_map, PredictedSchedule.Group.prediction_map_t) :: [map_key_t]
  defp get_trips(schedule_map, prediction_map) do
    [prediction_map, schedule_map]
    |> Enum.map(&Map.keys/1)
    |> Enum.concat
    |> Enum.uniq
  end

  @spec build_schedule_pair_map({Schedule.t, Schedule.t}, schedule_pair_map) :: schedule_pair_map
  defp build_schedule_pair_map({departure, arrival}, schedule_pair_map) do
    key = departure.trip
    Map.put(schedule_pair_map, key, {departure, arrival})
  end

  @spec build_schedule_map(Schedule.t, schedule_map) :: schedule_map
  defp build_schedule_map(schedule, schedule_map) do
    key = schedule.trip
    updater = fn(trip_map) -> Map.merge(trip_map, %{schedule.stop.id => schedule}) end
    Map.update(schedule_map, key, %{schedule.stop.id => schedule}, updater)
  end

  @spec first_trip([Schedule.t | Prediction.t | nil]) :: Trip.t | nil
  defp first_trip(list_with_trips) do
    list_with_trips
    |> Enum.reject(&is_nil/1)
    |> List.first
    |> Map.get(:trip)
  end

  @spec reversed_stop_time?(StopTime.t) :: boolean
  defp reversed_stop_time?(stop_time) do
    case {StopTime.departure_time(stop_time), StopTime.arrival_time(stop_time)} do
      {nil, _} ->
        # no departure time, ignore the stop time
        true
      {_, nil} ->
        false
      {departure_time, arrival_time} ->
        Timex.after?(departure_time, arrival_time)
    end
  end

  # reject predictions which are going in the wrong direction from the schedule
  @spec match_schedule_direction([{Schedule.t, Schedule.t}], [Prediction.t]) :: [Prediction.t]
  defp match_schedule_direction(schedule_pairs, predictions)
  defp match_schedule_direction([], predictions) do
    predictions
  end
  defp match_schedule_direction([{departure_schedule, _} | _], predictions) do
    direction_id = departure_schedule.trip.direction_id
    Enum.filter(predictions, &match?(%{direction_id: ^direction_id}, &1))
  end
end
