defmodule StopTimeListTest do
  use ExUnit.Case, async: true
  import StopTimeList

  alias Schedules.{Schedule, Trip, Stop}
  alias Predictions.Prediction
  alias Routes.Route

  @time ~N[2017-01-01T22:30:00]
  @route %Route{id: "86", type: 3, name: "86"}

  @sched_stop1_trip1__7_00 %Schedule{
    time: ~N[2017-01-01T07:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip1"}
  }

  @sched_stop1_trip2__8_00 %Schedule{
    time: ~N[2017-01-01T08:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop1_trip3__9_00 %Schedule{
    time: ~N[2017-01-01T09:00:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip3"}
  }

  @sched_stop2_trip2__8_15 %Schedule{
    time: ~N[2017-01-01T08:15:00],
    route: @route,
    stop: %Stop{id: "stop2"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop3_trip1__7_30 %Schedule{
    time: ~N[2017-01-01T07:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip1"}
  }

  @sched_stop3_trip2__8_30 %Schedule{
    time: ~N[2017-01-01T08:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip2"}
  }

  @sched_stop3_trip3__9_30 %Schedule{
    time: ~N[2017-01-01T09:30:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip3"}
  }

  @pred_stop1_trip2__8_05 %Prediction{
    time: ~N[2017-01-01T08:05:00],
    route: @route,
    stop: %Stop{id: "stop1"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop2_trip2__8_16 %Prediction{
    time: ~N[2017-01-01T08:16:00],
    route: @route,
    stop: %Stop{id: "stop2"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop3_trip2__8_32 %Prediction{
    time: ~N[2017-01-01T08:32:00],
    route: @route,
    stop: %Stop{id: "stop3"},
    trip: %Trip{id: "trip2"}
  }

  @pred_stop1_trip1__8_05 %Prediction{
      time: ~N[2017-01-01T08:05:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip1"}
  }

  @pred_stop1_trip2__8_16 %Prediction{
      time: ~N[2017-01-01T08:16:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip2"}
  }

  @pred_stop1_trip3__8_32 %Prediction{
      time: ~N[2017-01-01T08:32:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip3"}
  }

  @pred_stop1_trip4__8_35 %Prediction{
      time: ~N[2017-01-01T08:35:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip4"}
  }

  @pred_stop1_trip5__8_36 %Prediction{
      time: ~N[2017-01-01T08:36:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip5"}
  }

  @pred_stop1_trip6__8_37 %Prediction{
      time: ~N[2017-01-01T08:37:00],
      route: @route,
      stop: %Stop{id: "stop1"},
      trip: %Trip{id: "trip6"}
  }

  @pred_stop3_trip6__8_38 %Prediction{
      time: ~N[2017-01-01T08:38:00],
      route: @route,
      stop: %Stop{id: "stop3"},
      trip: %Trip{id: "trip6"}
  }

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  | 8:00  | 9:00
  # stop2 |       | 8:15  |
  # stop3 |       |       |

  @origin_schedules [
      @sched_stop1_trip3__9_00,
      @sched_stop1_trip1__7_00,
      @sched_stop1_trip2__8_00,
      @sched_stop2_trip2__8_15,
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 | 7:00  | 8:00  | 9:00
  # stop2 |       |       |
  # stop3 | 7:30  | 8:30  | 9:30

  @od_schedules [
      { @sched_stop1_trip2__8_00, @sched_stop3_trip2__8_30 },
      { @sched_stop1_trip1__7_00, @sched_stop3_trip1__7_30 },
      { @sched_stop1_trip3__9_00, @sched_stop3_trip3__9_30 },
  ]

  # ------------------------------
  #         trip1 | trip2 | trip3
  # ------------------------------
  # stop1 |       | 8:05  |
  # stop2 |       | 8:16  |
  # stop3 |       | 8:32  |

  # shuffled to make sure we aren't order dependent
  @predictions [
    @pred_stop1_trip2__8_05,
    @pred_stop3_trip2__8_32,
    @pred_stop2_trip2__8_16,
  ]

  # -----------------------------------------------------
  #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
  # -----------------------------------------------------
  # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
  # stop2 |       |       |       |       |       |
  # stop3 |       |       |       |       |       | 8:38

  # shuffled to make sure we aren't order dependent
  @origin_destination_predictions [
    @pred_stop1_trip6__8_37,
    @pred_stop1_trip4__8_35,
    @pred_stop1_trip3__8_32,
    @pred_stop1_trip5__8_36,
    @pred_stop1_trip1__8_05,
    @pred_stop1_trip2__8_16,
    @pred_stop3_trip6__8_38,
  ]

  describe "has_predictions?/1" do
    test "true when any of the stop times have a prediction" do
      for {schedules, origin_id, destination_id} <- [
            {@origin_schedules, "stop1", nil},
            {@od_schedules, "stop1", "stop2"},
            {@od_schedules, "stop1", "stop3"},
            {@od_schedules, "stop2", "stop3"}] do
          assert schedules
          |> build(@predictions, origin_id, destination_id, :keep_all, @time, true)
          |> has_predictions?
      end
    end

    test "false when there are no predictions" do
      for {schedules, destination_id} <- [
            {@origin_schedules, nil},
            {@od_schedules, "stop2"}] do
          refute schedules
          |> build([], "stop1", destination_id, :keep_all, @time, true)
          |> has_predictions?

      end
    end
  end

  describe "build/1 with no origin or destination" do
    test "returns no times" do
      assert build(@origin_schedules, @predictions, nil, nil, :keep_all, @time, true) == %StopTimeList{times: []}
    end
  end

  describe "build/1 with only origin" do
    test "returns StopTimes at that origin sorted by time with predictions first" do

      # --------------------------------------------
      #         trip1   | trip2           | trip3
      # --------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00(s)
      # stop2 |         | 8:15(s) 8:16(p) |
      # stop3 |         | 8:32(p)         |


      result = build(@origin_schedules, @predictions, "stop1", nil, :predictions_then_schedules, @time, true)

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip3"}
          }
        ]
      }
    end

    test "includes predictions without scheduled departures" do
      prediction = %Prediction{
        time: ~N[2017-01-01T07:05:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip1"}
      }
      result = build(Enum.filter(@origin_schedules, & &1.trip.id != "trip1"), [prediction | @predictions], "stop1", nil, :predictions_then_schedules, @time, true)

      assert List.first(result.times) == %StopTime{
        arrival: nil,
        departure: %PredictedSchedule{
          schedule: nil,
          prediction: prediction
        },
        trip: %Trip{id: "trip1"}
      }
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@origin_schedules, @predictions, "stop1", nil, :keep_all, @time, true)
      assert List.first(result.times) == %StopTime{
        trip: %Trip{id: "trip1"},
        departure: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "stop1"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        }}
    end

    test "removes all scheduled time before the last prediction" do
      prediction = %Prediction{
        time: ~N[2017-01-01T09:05:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip4"}
      }
      schedule = %Schedule{
        time: ~N[2017-01-01T10:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip5"}
      }

      result = build([schedule | @origin_schedules], [prediction | @predictions], "stop1", nil, :predictions_then_schedules, @time, true)
      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: %Prediction{
                time: ~N[2017-01-01T09:05:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip4"}
              }
            },
            trip: %Trip{id: "trip4"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T10:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip5"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip5"}
          },
        ]
      }
    end

    test "matches predictions and schedules with the same trip/stop even if the route is different" do
      prediction = %Prediction{
        time: ~N[2017-01-01T09:05:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip4"}
      }
      schedule = %Schedule{
        time: ~N[2017-01-01T10:00:00],
        route: %{@route | id: "different_route_id"},
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip4"}
      }

      result = build([schedule], [prediction], "stop1", nil, :predictions_then_schedules, @time, true)
      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: schedule,
              prediction: prediction
            },
            trip: %Trip{id: "trip4"}
          }
        ]
      }
    end

    test "only leaves upcoming trips and one previous" do

      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      result = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T08:30:00], true)

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip3"}
          },
        ]
      }

    end

    test "without predictions, :predictions_then_schedules is the same as :last_trip_and_upcoming" do

      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      expected = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T08:30:00], true)
      actual = build(@origin_schedules, [], "stop1", nil, :predictions_then_schedules, ~N[2017-01-01T08:30:00], true)

      assert expected == actual
    end

    test "returns all trips if they are upcoming" do

      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      result = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T06:30:00], true)

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T07:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip1"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip1"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip2"}
          },
          %StopTime{
            arrival: nil,
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            trip: %Trip{id: "trip3"}
          },
        ]
      }

    end

    test "returns all trips if they are all in the past" do
      # ------------------------------
      #         trip1 | trip2 | trip3
      # ------------------------------
      # stop1 | 7:00  | 8:00  | 9:00
      # stop2 |       | 8:15  |
      # stop3 |       |       |

      expected = build(@origin_schedules, [], "stop1", nil, :keep_all, ~N[2017-01-01T09:30:00], true)
      actual = build(@origin_schedules, [], "stop1", nil, :last_trip_and_upcoming, ~N[2017-01-01T09:30:00], true)

      assert actual == expected
    end
  end

  describe "build/1 with origin and destination" do

    test "with origin and destination provided, returns StopTimes with arrivals and departures" do

      # --------------------------------------------
      #         trip1   | trip2           | trip3
      # --------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00(s)
      # stop2 |         | 8:16(p)         |
      # stop3 | 7:30(s) | 8:30(s) 8:32(p) | 9:30(s)

      result = build(@od_schedules, @predictions, "stop1", "stop3", :predictions_then_schedules, @time, true)

      assert result == %StopTimeList{
        times: [
          %StopTime{
            arrival: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:30:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:32:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip2"}
              }
            },
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T08:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              },
              prediction: %Prediction{
                time: ~N[2017-01-01T08:05:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip2"}
              }
            },
            trip: %Trip{id: "trip2"}},
          %StopTime{
            arrival: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:30:00],
                route: @route,
                stop: %Stop{id: "stop3"},
                trip: %Trip{id: "trip3"}
              },
              prediction: nil
            },
            departure: %PredictedSchedule{
              schedule: %Schedule{
                time: ~N[2017-01-01T09:00:00],
                route: @route,
                stop: %Stop{id: "stop1"},
                trip: %Trip{id: "trip3"}
              },
            prediction: nil
            },
            trip: %Trip{id: "trip3"}
          }
        ]
      }
    end

    test "includes arrival predictions without corresponding departure predictions" do
      orig_sched = %Schedule{
          time: ~N[2017-01-01T06:10:00],
          route: @route,
          stop: %Stop{id: "stop1"},
          trip: %Trip{id: "t_new"}
        }

        dest_sched = %Schedule{
          time: ~N[2017-01-01T06:30:00],
          route: @route,
          stop: %Stop{id: "stop3"},
          trip: %Trip{id: "t_new"}
        }

      schedule_pair = {orig_sched, dest_sched}

      prediction = %Prediction{
        time: ~N[2017-01-01T07:31:00],
        route: @route,
        stop: %Stop{id: "stop3"},
        trip: %Trip{id: "t_new"}
      }

      # --------------------------------------------------
      #         trip1   | trip2           | trip3 | t_new
      # --------------------------------------------------
      # stop1 | 7:00(s) | 8:00(s) 8:05(p) | 9:00  | 6:10(s)
      # stop2 |         | 8:16(p)         |       |
      # stop3 | 7:30(s) | 8:30(s) 8:32(p) | 9:30  | 6:30(s) 7:31(p)

      result = build([schedule_pair | @od_schedules], [prediction | @predictions], "stop1", "stop3", :last_trip_and_upcoming, ~N[2017-01-01T06:15:00], true)
      stop_time = hd(result.times)

      assert stop_time == %StopTime{
        departure: %PredictedSchedule{schedule: orig_sched, prediction: nil},
        arrival: %PredictedSchedule{schedule: dest_sched, prediction: prediction},
        trip: %Schedules.Trip{id: "t_new"}
      }
    end

    test "when trips are cancelled, returns the schedules with those cancel predictions" do
      cancel_stop1_trip2 = %{@pred_stop1_trip2__8_16 | time: nil, schedule_relationship: :cancelled}
      cancel_stop3_trip2 = %{@pred_stop3_trip2__8_32 | time: nil, schedule_relationship: :cancelled}
      # cancellations for the right stops, but a trip going the other direction
      cancel_stop1_trip6 = %{@pred_stop1_trip6__8_37 | time: nil, schedule_relationship: :cancelled, direction_id: 1}
      cancel_stop3_trip6 = %{@pred_stop3_trip6__8_38 | time: nil, schedule_relationship: :cancelled, direction_id: 1}
      predictions = [cancel_stop3_trip6, cancel_stop1_trip6, cancel_stop3_trip2, cancel_stop1_trip2]

      result = build(@od_schedules, predictions, "stop1", "stop3", :keep_all, ~N[2017-01-01T08:00:00], true)
      stop_time = Enum.at(result.times, 1) # should be trip 2

      assert PredictedSchedule.trip(stop_time.departure) == %Trip{id: "trip2"}
      assert stop_time.departure.prediction == cancel_stop1_trip2
      assert stop_time.arrival.prediction == cancel_stop3_trip2
    end

    test "when showing all, can return schedules before predictions" do
      result = build(@od_schedules, @predictions, "stop1", "stop3", :keep_all, @time, true)
      assert List.first(result.times) == %StopTime{
        trip: %Trip{id: "trip1"},
        departure: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:00:00],
            route: @route,
            stop: %Stop{id: "stop1"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        },
        arrival: %PredictedSchedule{
          schedule: %Schedule{
            time: ~N[2017-01-01T07:30:00],
            route: @route,
            stop: %Stop{id: "stop3"},
            trip: %Trip{id: "trip1"}
          },
          prediction: nil
        }}
    end
  end

  describe "build_predictions_only/4" do
    test "Results contain no schedules for origin" do
      result = build_predictions_only([], @origin_destination_predictions, "stop1", nil).times
      assert length(result) == 5
      for stop_time <- result do
        assert %StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: nil} = stop_time
      end
    end

    test "Results contain the first 5 predictions regardless of original order" do
      # trip needs to have a headsign to trigger bug
      early_prediction = %Prediction{trip: %Trip{id: "trip0", headsign: "other"},
                                     route: @route,
                                     stop: %Stop{id: "stop1"},
                                     time: ~N[2017-01-01T00:00:00]}
      result = build_predictions_only([], @origin_destination_predictions ++ [early_prediction], "stop1", nil).times
      assert List.first(result).departure.prediction == early_prediction
    end

    test "Results contain no schedules for origin and destination" do

      # -----------------------------------------------------
      #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
      # -----------------------------------------------------
      # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
      # stop2 |       |       |       |       |       |
      # stop3 |       |       |       |       |       | 8:38

      result = build_predictions_only([], @origin_destination_predictions, "stop1", "stop3").times

      assert length(result) == 1

      stop_time = hd(result)
      assert stop_time.trip.id == "trip6"
      assert %StopTime{departure: %PredictedSchedule{schedule: nil}, arrival: %PredictedSchedule{schedule: nil}} = stop_time
    end

    test "All times have departure predictions" do

      # -----------------------------------------------------
      #         trip1 | trip2 | trip3 | trip4 | trip5 | trip6
      # -----------------------------------------------------
      # stop1 | 8:05  | 8:16  | 8:32  | 8:35  | 8:36  | 8:37
      # stop2 |       |       |       |       |       |
      # stop3 |       |       |       |       |       | 8:38

      result = build_predictions_only([], @origin_destination_predictions, "stop1", "stop3").times
      assert length(result) == 1

      stop_time = hd(result)
      assert stop_time.trip.id == "trip6"
      assert stop_time.departure.prediction != nil
    end

    test "uses an arrival schedule if present and does not set a prediction" do
      departure_prediction = @pred_stop1_trip2__8_16
      arrival_schedule = {@sched_stop1_trip2__8_00, @sched_stop3_trip2__8_30}

      result = build_predictions_only([arrival_schedule], [departure_prediction], "stop1", "stop3").times

      assert [stop_time] = result
      assert stop_time.trip.id == "trip2"
      assert stop_time.departure.schedule
      assert stop_time.departure.prediction
      assert stop_time.arrival.schedule
      refute stop_time.arrival.prediction
    end

    test "uses an arrival prediction if present with a schedule" do
      departure_prediction = @pred_stop1_trip2__8_16
      arrival_prediction = @pred_stop3_trip2__8_32
      arrival_schedule = {@sched_stop1_trip2__8_00, @sched_stop3_trip2__8_30}

      result = build_predictions_only([arrival_schedule], [departure_prediction, arrival_prediction], "stop1", "stop3").times

      assert [stop_time] = result
      assert stop_time.trip.id == "trip2"
      assert stop_time.departure.schedule
      assert stop_time.departure.prediction
      assert stop_time.arrival.schedule
      assert stop_time.arrival.prediction
    end

    test "does not use schedules if there are no predictions" do
      result = build_predictions_only([@sched_stop3_trip2__8_30], [], "stop3", nil).times

      assert result == []
    end

    test "handles predictions not associated with a trip" do
      prediction = %Prediction{
        id: "pred",
        time: Util.now,
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: nil
      }
      result = build_predictions_only([], [prediction], "stop1", nil)
      assert result == %StopTimeList{
        times: [
          %StopTime{
            trip: nil,
            departure: %PredictedSchedule{
              schedule: nil,
              prediction: prediction
            }}
        ]}
    end

    test "handles predictions not associated with a trip on different routes" do
      stop = %Stop{id: "stop1"}
      prediction = %Prediction{
        id: "pred",
        route: @route,
        stop: stop,
        status: "2 stops away"}
      other_prediction = %Prediction{
        id: "other pred",
        route: %Route{id: "other"},
        stop: stop,
        status: "1 stop away"}
      result = build_predictions_only([], [prediction, other_prediction] |> Enum.shuffle, "stop1", nil)
      assert [
        %StopTime{trip: nil, departure: %PredictedSchedule{prediction: ^other_prediction}},
        %StopTime{trip: nil, departure: %PredictedSchedule{prediction: ^prediction}}
      ] = result.times
    end

    test "ignores predictions where arrival is before departure" do
      prediction = %Prediction{
        time: ~N[2017-01-01T12:00:00],
        route: @route,
        stop: %Stop{id: "stop1"},
        trip: %Trip{id: "trip1"}
      }
      arrival_prediction = %{prediction | time: ~N[2016-12-31T12:00:00], stop: %Stop{id: "stop3"}}
      predictions = [prediction, arrival_prediction]
      result = build_predictions_only([], predictions, "stop1", "stop3")
      assert result.times == []
    end
  end
end
