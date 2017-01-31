defmodule StopTimeTest do
  use ExUnit.Case, async: true
  import StopTimeList

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction
  alias Routes.Route
  alias StopTimeList.StopTime

  @route %Route{id: "86", type: 3, name: "86"}
  @origin_schedules [
    %Schedule{
      time: ~N[2017-01-01T09:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t3"}
    },
    %Schedule{
      time: ~N[2017-01-01T07:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t1"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:00:00],
      route: @route,
      stop: %Stop{id: "1"},
      trip: %Trip{id: "t2"}
    },
    %Schedule{
      time: ~N[2017-01-01T08:15:00],
      route: @route,
      stop: %Stop{id: "2"},
      trip: %Trip{id: "t2"}
    }
  ]
  @od_schedules [
    {
      %Schedule{
        time: ~N[2017-01-01T08:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t2"}
      },
      %Schedule{
        time: ~N[2017-01-01T08:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t2"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T07:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t1"}
      },
      %Schedule{
        time: ~N[2017-01-01T07:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t1"}
      }
    },
    {
      %Schedule{
        time: ~N[2017-01-01T09:00:00],
        route: @route,
        stop: %Stop{id: "1"},
        trip: %Trip{id: "t3"}
      },
      %Schedule{
        time: ~N[2017-01-01T09:30:00],
        route: @route,
        stop: %Stop{id: "3"},
        trip: %Trip{id: "t3"}
      }
    }
  ]
  @predictions [
    %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route_id: @route.id,
      stop_id: "2",
      trip: %Trip{id: "t2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route_id: @route.id,
      stop_id: "3",
      trip: %Trip{id: "t2"}
    }
  ]

  @origin_destination_predictions [
    %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t1"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t2"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t3"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:35:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t4"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:36:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t5"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:37:00],
      route_id: @route.id,
      stop_id: "1",
      trip: %Trip{id: "t6"}
    },
    %Prediction{
      time: ~N[2017-01-01T08:38:00],
      route_id: @route.id,
      stop_id: "3",
      trip: %Trip{id: "t6"}
    }
  ]

  describe "build/1 with no origin or destination" do
    test "returns no times" do
      assert build(@origin_schedules, @predictions, nil, nil, true) == %StopTimeList{times: [], showing_all?: true}
    end
  end

  describe "build/1 with only origin" do
    test "returns StopTimes at that origin sorted by time with predictions first" do
      result = build(@origin_schedules, @predictions, "1", nil, false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: nil,
            departure: {
              %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "1",
                trip: %Trip{id: "t2"}
              }
            },
            trip: %Trip{id: "t2"}
          },
          %StopTimeList.StopTime{
            arrival: nil,
            departure: {
              %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            trip: %Trip{id: "t3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:05:00],
        route_id: @route.id,
        stop_id: "1",
        trip: %Trip{id: "t1"}
      }
      result = build(Enum.filter(@origin_schedules, & &1.trip.id != "t1"), [prediction | @predictions], "1", nil, false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: nil,
        departure: {
          nil,
          prediction
        },
        trip: %Trip{id: "t1"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@origin_schedules, @predictions, "1", nil, true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "t1"},
        departure: {
          %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "1"},
            trip: %Trip{id: "t1"}
          },
          nil
        }}
    end
  end

  describe "build/1 with origin and destination" do
    test "with origin and destination provided, returns StopTimes with arrivals and departures" do
      result = build(@od_schedules, @predictions, "1", "3", false)

      assert result == %StopTimeList{
        times: [
          %StopTimeList.StopTime{
            arrival: {
              %Schedule{
                time: ~N[2017-01-01T08:30:00],
                route: @route,
                stop: %Stop{id: "3"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:32:00],
                route_id: @route.id,
                stop_id: "3",
                trip: %Trip{id: "t2"}
              }
            },
            departure: {
              %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t2"}
              },
              %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route_id: @route.id,
                stop_id: "1",
                trip: %Trip{id: "t2"}
              }
            },
            trip: %Trip{id: "t2"}},
          %StopTimeList.StopTime{
            arrival: {
              %Schedule{
                time: ~N[2017-01-01T09:30:00],
                route: @route,
                stop: %Stop{id: "3"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            departure: {
              %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "1"},
                trip: %Trip{id: "t3"}
              },
              nil
            },
            trip: %Trip{id: "t3"}
          }
        ],
        showing_all?: false
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "3",
        trip: %Trip{id: "t_new"}
      }
      result = build(@od_schedules, [prediction | @predictions], "1", "3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        arrival: {nil, prediction},
        departure: {nil, nil},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "includes arrival predictions without corresponding departure predictions" do
      schedule_pair = {
        %Schedule{
          time: ~N[2017-01-01T07:00:00],
          route: @route,
          stop: %Stop{id: "1"},
          trip: %Trip{id: "t_new"}
        },
        %Schedule{
          time: ~N[2017-01-01T07:30:00],
          route: @route,
          stop: %Stop{id: "3"},
          trip: %Trip{id: "t_new"}
        }
      }
      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route_id: @route.id,
        stop_id: "3",
        trip: %Trip{id: "t_new"}
      }
      result = build([schedule_pair | @od_schedules], [prediction | @predictions], "1", "3", false)

      assert List.first(result.times) == %StopTimeList.StopTime{
        departure: {elem(schedule_pair, 0), nil},
        arrival: {elem(schedule_pair, 1), prediction},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@od_schedules, @predictions, "1", "3", true)
      assert List.first(result.times) == %StopTimeList.StopTime{
        trip: %Trip{id: "t1"},
        departure: {
          %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "1"},
            trip: %Trip{id: "t1"}
          },
          nil
        },
        arrival: {
          %Schedule{
            time: ~N[2017-01-01T07:30:00],
            route: @route,
            stop: %Stop{id: "3"},
            trip: %Trip{id: "t1"}
          },
          nil
        }}
    end
  end

  describe "build_predictions_only/3" do
    test "Results contain no schedules for origin" do
      result = build_predictions_only(@origin_destination_predictions, "1", nil).times
      assert length(result) == 5
      for stop_time <- result do
        assert %StopTimeList.StopTime{departure: {nil, _}, arrival: nil} = stop_time
      end
    end

    test "Results contain no schedules for origin and destination" do
      result = build_predictions_only(@origin_destination_predictions, "1", "3").times
      assert length(result) == 5
      for stop_time <- result do
        assert %StopTimeList.StopTime{departure: {nil, _}, arrival: {nil, _}} = stop_time
      end
    end

    test "All times have departure predictions" do
      result = build_predictions_only(@origin_destination_predictions, "1", "3").times
      assert length(result) == 5
      for stop_time <- result do
        assert elem(stop_time.departure, 1) != nil
      end
    end

    test "handles predictions not associated with a trip" do
      prediction = %Prediction{
        time: Util.now,
        route_id: @route.id,
        stop_id: "1",
        trip: nil
      }
      result = build_predictions_only([prediction], "1", nil)
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTimeList.StopTime{
            trip: nil,
            departure: {
              nil,
              prediction
            }}
        ]}
    end

    test "handles predictions not associated with a trip given an origin and destination" do
      prediction = %Prediction{
        time: Util.now,
        route_id: @route.id,
        stop_id: "1",
        trip: nil
      }
      arrival_prediction = %{prediction | stop_id: "3"}
      predictions = [prediction, arrival_prediction]
      result = build_predictions_only(predictions, "1", "3")
      assert result == %StopTimeList{
        showing_all?: true,
        times: [
          %StopTimeList.StopTime{
            trip: nil,
            departure: {
              nil,
              prediction
            },
            arrival: {
              nil,
              arrival_prediction}}
        ]}
    end
  end

  describe "StopTime.display_status/1" do
    test "returns the same as StopTime.display_status/2 with a nil second argument" do
      assert StopTime.display_status({nil, %Prediction{status: "On Time"}}) == StopTime.display_status({nil, %Prediction{status: "On Time"}}, nil)
    end
  end

  describe "StopTime.display_status/2" do
    test "uses the departure status if it exists" do
      result = StopTime.display_status({nil, %Prediction{status: "On Time"}}, nil)

      assert IO.iodata_to_binary(result) == "On Time"
    end

    test "includes track number if present" do
      result = StopTime.display_status({nil, %Prediction{status: "All Aboard", track: "5"}}, nil)

      assert IO.iodata_to_binary(result) == "All Aboard on track 5"
    end

    test "returns a readable message if there's a difference between the scheduled and predicted times" do
      now = Util.now
      result = StopTime.display_status({%Schedule{time: now}, %Prediction{time: Timex.shift(now, minutes: 5)}}, {nil, nil})

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "returns the empty string if the predicted and scheduled times are the same" do
      now = Util.now
      result = StopTime.display_status({%Schedule{time: now}, %Prediction{time: now}}, {nil, nil})

      assert IO.iodata_to_binary(result) == ""
    end

    test "takes the max of the departure and arrival time delays" do
      departure = Util.now
      arrival = Timex.shift(departure, minutes: 30)
      result = StopTime.display_status(
        {%Schedule{time: departure}, %Prediction{time: Timex.shift(departure, minutes: 5)}},
        {%Schedule{time: arrival}, %Prediction{time: Timex.shift(arrival, minutes: 10)}}
      )

      assert IO.iodata_to_binary(result) == "Delayed 10 minutes"
    end

    test "handles nil arrivals" do
      now = Util.now
      result = StopTime.display_status({%Schedule{time: now}, %Prediction{time: Timex.shift(now, minutes: 5)}}, nil)

      assert IO.iodata_to_binary(result) == "Delayed 5 minutes"
    end

    test "inflects the delay correctly" do
      now = Util.now
      result = StopTime.display_status({%Schedule{time: now}, %Prediction{time: Timex.shift(now, minutes: 1)}}, nil)

      assert IO.iodata_to_binary(result) == "Delayed 1 minute"
    end
  end

  describe "StopTime.delay/1" do
    test "returns the difference between a schedule and prediction" do
      now = Util.now

      assert StopTime.delay({%Schedule{time: now}, %Prediction{time: Timex.shift(now, minutes: 14)}}) == 14
    end

    test "returns 0 if either time is nil, or if the argument itself is nil" do
      now = Util.now
      assert StopTime.delay({nil, %Prediction{time: Timex.shift(now, minutes: 14)}}) == 0
      assert StopTime.delay({%Schedule{time: now}, nil}) == 0
      assert StopTime.delay({nil, nil}) == 0
      assert StopTime.delay(nil) == 0
    end
  end
end
