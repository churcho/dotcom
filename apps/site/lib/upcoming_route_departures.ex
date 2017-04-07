defmodule UpcomingRouteDepartures do
  @moduledoc """
  UpcomingRouteDepartures are used to hold information about upcoming departures. UpcomingRouteDepartures
  have a route, a direction, and a list
  of departures. A Departure is a tuple {Headsign, [PredictedSchedule]}.
  """

  alias Routes.Route
  alias Predictions.Prediction
  alias Schedules.Schedule

  @limit 3

  defstruct [
    route: %Route{},
    direction: 0,
    departures: []

  ]
  @type t :: %__MODULE__{
    route: Route.t,
    direction: 0 | 1,
    departures: [{String.t, [PredictedSchedule.t]}]
  }

  @doc """
  Builds a list of {mode, [route_time]}
  Given a list of predictions, a list of schedules, a time, and a limit, it will return list of
  `UpcomingRouteDepartures`'s for each mode available in the given predictions and schedules.
  """
  @spec build_mode_list([Prediction.t], [Schedule.t], DateTime.t, non_neg_integer) ::
                        [{Route.gtfs_route_type, [UpcomingRouteDepartures.t]}]
  def build_mode_list(predictions, schedules, current_time, limit \\ @limit) do
    filtered_schedules = Enum.reject(schedules, &Routes.Repo.route_hidden?(&1.route))
    predictions
    |> PredictedSchedule.group(filtered_schedules)
    |> build_route_times(current_time, limit)
    |> Enum.group_by(&Route.type_atom(&1.route.type)) # Group by modes
    |> Enum.map(fn {mode, route_times} -> {mode, sort_route_times(route_times)} end)
  end

  @spec build_route_times([PredictedSchedule.t], DateTime.t, non_neg_integer) :: [UpcomingRouteDepartures.t]
  defp build_route_times(predicted_schedules, current_time, limit) do
    predicted_schedules
    |> valid_departures(current_time)
    |> Enum.group_by(&{PredictedSchedule.route(&1), PredictedSchedule.trip(&1).direction_id})
    |> Enum.map(&build_route_time(&1, limit))
  end

  # Builds a Route time with headsigns grouped together
  @spec build_route_time({{Route.t, 0 | 1}, [PredictedSchedule.t]}, non_neg_integer) :: UpcomingRouteDepartures.t
  defp build_route_time({{route, direction_id}, predicted_schedules}, limit) do
    predicted_schedules
    |> Enum.group_by(&PredictedSchedule.trip(&1).headsign)
    |> Enum.map(&limited_departures(&1, limit))
    |> do_build_route_time(route, direction_id)
  end

  @spec do_build_route_time(%{String.t => [PredictedSchedule.t]}, Route.t, 0 | 1) :: UpcomingRouteDepartures.t
  defp do_build_route_time(grouped_predictions, route, direction_id) do
    %__MODULE__{
      route: route,
      direction:  direction_id,
      departures: grouped_predictions
    }
  end

  # Take the `limit` soonest departures
  @spec limited_departures({String.t, [PredictedSchedule.t]}, non_neg_integer) :: {String.t, [PredictedSchedule.t]}
  defp limited_departures({headsign, predicted_schedules}, limit) do
    {headsign,
      predicted_schedules
      |> Enum.sort_by(&PredictedSchedule.time/1)
      |> Enum.take(limit)}
  end

  # Departures are valid if passengers can board, and the departure time is in the future
  @spec valid_departures([PredictedSchedule.t], DateTime.t) :: [PredictedSchedule.t]
  defp valid_departures(predicted_schedules, current_time) do
    predicted_schedules
    |> Enum.filter(&PredictedSchedule.departing?/1)
    |> Enum.filter(&PredictedSchedule.upcoming?(&1, current_time))
  end

  @spec sort_route_times([UpcomingRouteDepartures.t]) :: [UpcomingRouteDepartures.t]
  defp sort_route_times(route_times) do
    Enum.sort_by(route_times, &route_time_sorter/1)
  end

  # Sorts bus according to number and name. Busses without a
  # numbered name are sorted by name. Otherwise, it is sorted by number
  # All other routes are sorted by name
  @spec route_time_sorter(UpcomingRouteDepartures.t) :: {number, number | String.t}
  defp route_time_sorter(%__MODULE__{route: %Route{type: 3, name: name}}) do
    case Integer.parse(name) do
      {i, ""} -> {1, i}
      _ -> {0, name}
    end
  end
  defp route_time_sorter(route_time) do
    route_time.route.name
  end
end
