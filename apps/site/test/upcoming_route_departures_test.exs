defmodule UpcomingRouteDeparturesTest do
  use ExUnit.Case, async: true
  import UpcomingRouteDepartures
  alias Routes.Route
  alias Schedules.{Schedule, Trip}
  alias Predictions.Prediction

  @time ~N[2017-01-01T22:30:00]
  @stop %Stops.Stop{id: 1}

  @schedules [
    %Schedule{
      route: %Route{id: "CR-1", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-1", headsign: "HS-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule{
      route: %Route{id: "CR-1", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-2", headsign: "HS-2", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule{
      route: %Route{id: "CR-1", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-3", headsign: "HS-2", direction_id: 0},
      time: Timex.shift(@time, minutes: 20),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule{
      route: %Route{id: "CR-1", type: 2},
      stop: @stop,
      trip: %Trip{id: "Early Schedule", headsign: "HS-2", direction_id: 0},
      time: Timex.shift(@time, minutes: -20),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule{
      route: %Route{id: "CR-2", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-4", headsign: "HS-1", direction_id: 1},
      time: Timex.shift(@time, minutes: 20),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule{
      route: %Route{id: "Non departure", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-5", headsign: "HS-1", direction_id: 1},
      time: Timex.shift(@time, minutes: 20),
      pickup_type: 1,
      stop_sequence: 1
    },
    %Schedule {
      route: %Route{id: "Green-B", type: 0},
      stop: @stop,
      trip: %Trip{id: "GREEN-1", headsign: "GREEN-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule {
      route: %Route{id: "66", type: 3, name: "66"},
      stop: @stop,
      trip: %Trip{id: "BUS-66-1", headsign: "BUS-HS-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule {
      route: %Route{id: "9", type: 3, name: "9"},
      stop: @stop,
      trip: %Trip{id: "BUS-9-1", headsign: "BUS-HS-2", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
    %Schedule {
      route: %Route{id: "742", type: 3, name: "SL1"},
      stop: @stop,
      trip: %Trip{id: "BUS-SL1-1", headsign: "BUS-HS-4", direction_id: 0},
      time: Timex.shift(@time, minutes: 5),
      pickup_type: 2,
      stop_sequence: 1
    },
  ]

  @predictions [
    %Prediction {
      route: %Route{id: "CR-1", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-1", headsign: "HS-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 4),
      departing?: true,
      stop_sequence: 1
    },
    %Prediction {
      route: %Route{id: "CR-2", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-4", headsign: "HS-1", direction_id: 1},
      time: Timex.shift(@time, minutes: 20),
      departing?: true,
      stop_sequence: 1
    },
    %Prediction {
      route: %Route{id: "Green-B", type: 0},
      stop: @stop,
      trip: %Trip{id: "GREEN-1", headsign: "GREEN-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 4),
      departing?: true,
      stop_sequence: 1
    },
    %Prediction {
      route: %Route{id: "Non departure", type: 2},
      stop: @stop,
      trip: %Trip{id: "CR-TRIP-5", headsign: "HS-1", direction_id: 0},
      time: Timex.shift(@time, minutes: 20),
      departing?: false,
      stop_sequence: 1
    },
    %Prediction {
      route: %Route{id: "Early Prediction Route", type: 2},
      stop: @stop,
      trip: %Trip{id: "Early Prediction Trip", headsign: "HS-1", direction_id: 1},
      time: Timex.shift(@time, minutes: 20),
      departing?: true,
      stop_sequence: 1
    }
  ]

  describe "build_mode_list/4" do
    test "PredictedSchedules are grouped by mode" do
      mode_map = @predictions |> build_mode_list(@schedules, @time, 2) |> Map.new()
      for type_integer_val <- [0,2,3] do
        for route_time <- mode_map[Route.type_atom(type_integer_val)] do
          assert route_time.route.type == type_integer_val
        end
      end
    end

    test "UpcomingRouteDepartures are grouped by headsign" do
      mode_map = @predictions |> build_mode_list(@schedules, @time, 2) |> Map.new()
      commuter_route_times = mode_map[:commuter_rail]
      for route_time <- commuter_route_times do
        for {headsign, predicted_schedules} <- route_time.departures do
          Enum.all?(predicted_schedules, & PredictedSchedule.trip(&1).headsign == headsign)
        end
      end
    end

    test "UpcomingRouteDepartures' predicted_schedules are limited to `limit`" do
      for {_mode, route_times} <- build_mode_list(@predictions, @schedules, @time, 1) do
        for route_time <- route_times do
          for {_headsign, predicted_schedules} <- route_time.departures do
            assert [_] = predicted_schedules # single predicted_schedule
          end
        end
      end
    end

    test "Only upcoming times are returned" do
      for {_mode, route_times} <- build_mode_list(@predictions, @schedules, @time, 5) do
        for route_time <- route_times do
          for {_headsign, predicted_schedules} <- route_time.departures do
            for predicted_schedule <- predicted_schedules do
              assert Timex.after?(PredictedSchedule.time(predicted_schedule), @time)
            end
          end
        end
      end
    end

    test "Bus routes are sorted in increasing route number" do
      mode_map = @predictions |> build_mode_list(@schedules, @time, 2) |> Map.new()
      bus_route_names = mode_map[:bus] |> Enum.map(& &1.route.name)
      assert bus_route_names == ["SL1", "9", "66"]
    end

    test "Only departing predicted_schedules are returned" do
      mode_map = @predictions |> build_mode_list(@schedules, @time, 2) |> Map.new()
      commuter_route_times = mode_map[:commuter_rail]
      refute Enum.find(commuter_route_times, & &1.route.id == "Non departure")
    end

    test "Same headsign can occur in separate routes" do
      mode_map = @predictions |> build_mode_list(@schedules, @time, 2) |> Map.new()
      commuter_route_times = mode_map[:commuter_rail]
      route1 = Enum.find(commuter_route_times, & &1.route.id == "CR-1")
      route2 = Enum.find(commuter_route_times, & &1.route.id == "CR-2")
      route1_headsigns = route1.departures |> Enum.map(&elem(&1, 0))
      route2_headsigns = route2.departures |> Enum.map(&elem(&1, 0))
      assert "HS-1" in route1_headsigns
      assert "HS-1" in route2_headsigns
    end
  end
end
