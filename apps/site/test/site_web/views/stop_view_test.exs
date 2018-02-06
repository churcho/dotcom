defmodule SiteWeb.StopViewTest do
  @moduledoc false
  import SiteWeb.StopView
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias Stops.Stop
  alias Routes.Route
  alias Schedules.Schedule
  alias Predictions.Prediction
  use SiteWeb.ConnCase, async: true

  describe "template_for_tab/1" do
    test "correct template for selected tab" do
      assert template_for_tab(nil) == "_info.html"
      assert template_for_tab("info") == "_info.html"
      assert template_for_tab("departures") == "_departures.html"
    end
  end

  describe "fare_mode/1" do
    test "types are separated as bus, subway or both" do
      assert fare_mode([:bus, :commuter_rail, :ferry]) == :bus
      assert fare_mode([:subway, :commuter_rail, :ferry]) == :subway
      assert fare_mode([:subway, :commuter_rail, :ferry, :bus]) == :bus_subway
    end
  end

  describe "accessibility_info" do
    @no_accessible_feature %Stop{id: "north", name: "test", accessibility: []}
    @no_accessible_with_feature %Stop{name: "name", accessibility: ["mini_high"]}
    @only_accessible_feature %Stop{name: "test", accessibility: ["accessible"]}
    @many_feature %Stop{name: "test", accessibility: ["accessible", "ramp", "elevator"]}
    @unknown_accessibly  %Stop{id: "44", name: "44", accessibility: ["unknown"]}

    test "Accessibility description reflects features" do
      has_text? accessibility_info(@unknown_accessibly), "Minor to moderate accessibility barriers exist"
      has_text? accessibility_info(@no_accessible_feature), "Significant accessibility barriers exist"
      has_text? accessibility_info(@no_accessible_with_feature), "Significant accessibility barriers exist"
      has_text? accessibility_info(@only_accessible_feature), "is accessible"
      has_text? accessibility_info(@many_feature), "has the following"
    end

    test "Contact link only appears for stops with accessibility features" do
      text = "Problem with an elevator"
      has_text? accessibility_info(@many_feature), text
      has_text? accessibility_info(@no_accessible_with_feature), text
      no_text? accessibility_info(@only_accessible_feature), text
      no_text? accessibility_info(@no_accessible_feature), text
      no_text? accessibility_info(@unknown_accessibly), text
    end

    defp has_text?(unsafe, text) do
      safe = unsafe
      |> Phoenix.HTML.html_escape
      |> Phoenix.HTML.safe_to_string
      assert safe =~ text
    end

    defp no_text?(unsafe, text) do
      safe = unsafe
      |> Phoenix.HTML.html_escape
      |> Phoenix.HTML.safe_to_string
      refute safe =~ text
    end
  end

  describe "pretty_accessibility/1" do
    test "formats phone and escalator fields" do
      assert pretty_accessibility("tty_phone") == ["TTY Phone"]
      assert pretty_accessibility("escalator_both") == ["Escalator (Up and Down)"]
    end

    test "For all other fields, separates underscore and capitalizes all words" do
      assert pretty_accessibility("elevator_issues") == ["Elevator Issues"]
      assert pretty_accessibility("down_escalator_repair_work") == ["Down Escalator Repair Work"]
    end

    test "ignores unknown and accessible features" do
      assert pretty_accessibility("unknown") == []
      assert pretty_accessibility("accessible") == []
    end
  end

  describe "sort_parking_spots/1" do
    test "parkings spots are sorted in correct order" do
      basic_spot = %{type: "basic"}
      accessible_spot = %{type: "accessible"}
      free_spot = %{type: "free"}
      sorted = sort_parking_spots([free_spot, basic_spot, accessible_spot])
      assert sorted == [basic_spot, accessible_spot, free_spot]
    end
  end

  describe "aggregate_routes/1" do
    test "All green line routes are aggregated" do
      e_line = %Route{id: "Green-E"}
      d_line = %Route{id: "Green-D"}
      c_line = %Route{id: "Green-C"}
      orange_line = %Route{id: "Orange"}
      line_list = [e_line, d_line, c_line, orange_line]
      aggregated_list = aggregate_routes(line_list)
      green_count = Enum.count(aggregated_list, & &1.id =~ "Green")

      assert green_count == 1
      assert Enum.count(aggregate_routes(line_list)) == 2
    end

    test "Mattapan is not aggregated" do
      orange_line = %Route{id: "Orange"}
      red_line = %Route{id: "Red"}
      mattapan = %Route{id: "Mattapan"}
      routes = [orange_line, red_line, mattapan] |> aggregate_routes |> Enum.map(& &1.id)
      assert Enum.count(routes) == 3
      assert "Red" in routes
      assert "Mattapan" in routes
    end
  end

  describe "location/1" do
    test "returns an encoded address if lat/lng is missing" do
      stop = %Stop{id: "place-sstat", latitude: nil, longitude: nil, address: "10 Park Plaza, Boston, MA"}
      assert location(stop) == "10%20Park%20Plaza%2C%20Boston%2C%20MA"
    end

    test "returns lat/lng as a string if lat/lng is available" do
      stop = %Stop{id: "2438", latitude: 42.37497, longitude: -71.102529}
      assert location(stop) == "#{stop.latitude},#{stop.longitude}"
    end
  end

  describe "fare_surcharge?/1" do
    test "returns true for South, North, and Back Bay stations" do
      for stop_id <- ["place-bbsta", "place-north", "place-sstat"] do
        assert fare_surcharge?(%Stop{id: stop_id})
      end
    end
  end

  describe "info_tab_name/1" do
    test "is stop info when given a bus line" do
      grouped_routes = [bus: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
        id: "742", key_route?: true, name: "SL2", type: 3}]]

      assert info_tab_name(grouped_routes) == "Stop Info"
    end

    test "is station info when given any other line" do
      grouped_routes = [
        bus: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "742", key_route?: true, name: "SL2", type: 3}],
        subway: [%Route{direction_names: %{0 => "Outbound", 1 => "Inbound"},
          id: "Red", key_route?: true, name: "Red", type: 1}]
      ]

      assert info_tab_name(grouped_routes) == "Station Info"
    end
  end

  describe "time_differences/2" do
    test "returns a list of rendered time differences" do
      date_time = ~N[2017-01-01T11:00:00]
      ps = %PredictedSchedule{schedule: %Schedule{time: ~N[2017-01-01T12:00:00]}}
      assert time_differences([ps], date_time) ==
        [PredictedSchedule.Display.time_difference(ps, date_time)]
    end

    test "time differences are in order from smallest to largest" do
      now = Util.now()
      schedules = [
        %PredictedSchedule{schedule: %Schedule{time: Timex.shift(now, minutes: 3)}},
        %PredictedSchedule{prediction: %Prediction{time: Timex.shift(now, minutes: 1)}},
        %PredictedSchedule{schedule: %Schedule{time: Timex.shift(now, minutes: 5)}},
      ]
      assert [one_min_live, three_mins, five_mins] = time_differences(schedules, now)
      assert safe_to_string(one_min_live) =~ "1 min"
      assert safe_to_string(one_min_live) =~ "icon-realtime"
      assert three_mins == ["3", " ", "mins"]
      assert five_mins == ["5", " ", "mins"]
    end

    test "sorts status predictions from closest to furthest" do
      date_time = ~N[2017-01-01T00:00:00]
      schedules = Enum.shuffle([
        %PredictedSchedule{prediction: %Prediction{status: "Boarding"}},
        %PredictedSchedule{prediction: %Prediction{status: "Approaching"}},
        %PredictedSchedule{prediction: %Prediction{status: "1 stop away"}},
        %PredictedSchedule{prediction: %Prediction{status: "2 stops away"}},
      ])
      assert [board, approach, one_stop] = time_differences(schedules, date_time)
      assert safe_to_string(board) =~ "Boarding"
      assert safe_to_string(approach) =~ "Approaching"
      assert safe_to_string(one_stop) =~ "1 stop away"
    end

    test "filters out predicted schedules we could not render" do
      date_time = ~N[2017-01-01T11:00:00]
      predicted_schedules = [
        %PredictedSchedule{}
      ]
      assert time_differences(predicted_schedules, date_time) == []
    end
  end

  @alerts [
    %Alerts.Alert{
      active_period: [
        {~N[2017-04-12T20:00:00], ~N[2017-05-12T20:00:00]}],
      description: "description",
      effect: :access_issue,
      header: "header", id: "1"}]

  describe "has_alerts?/3" do
    date = ~D[2017-05-11]
    informed_entity = %Alerts.InformedEntity{direction_id: 1, route: "556", route_type: nil, stop: nil, trip: nil}
    assert !has_alerts?(@alerts, date, informed_entity)
  end

  describe "render_alerts/3" do
    response = render_alerts(@alerts, ~D[2017-05-11], %Stop{id: "2438"})
    assert safe_to_string(response) =~ "alert-list-item"
  end

  describe "feature_icons/1" do
    test "returns list of featured icons" do
      [red_icon, access_icon | _] = feature_icons(%DetailedStop{features: [:red_line, :access]})
      assert safe_to_string(red_icon) =~ "icon-red-line"
      assert safe_to_string(access_icon) =~ "icon-access"
    end
  end

  describe "_info.html" do
    test "Ferry Fare link preselects origin", %{conn: conn} do
      output = SiteWeb.StopView.render("_info.html",
                                          stop_alerts: [],
                                          fare_name: "The Iron Price",
                                          date: ~D[2017-05-11],
                                          stop: %Stop{name: "Iron Island", id: "IronIsland"},
                                          grouped_routes: [{:ferry}],
                                          fare_sales_locations: [],
                                          terminal_stations: %{4 => ""},
                                          conn: conn)
      assert safe_to_string(output) =~ "/fares/ferry?origin=IronIsland"
    end
  end

  describe "_parking_lot.html" do
    @lot %{spots: [%{type: "basic", spots: 2}], rate: "$5/hr", note: "Parking notice", manager: nil, pay_by_phone_id: nil}

    test "Parking note is only shown when one exists" do
      note_output = SiteWeb.StopView.render("_parking_lot.html", lot: @lot)
      assert safe_to_string(note_output) =~ "Note"
      assert safe_to_string(note_output) =~ "Parking notice"
    end

    test "parking message is shown when lot has no parking" do
      output = SiteWeb.StopView.render("_parking_lot.html", lot: %{@lot | spots: []})
      assert safe_to_string(output) =~ "No MBTA parking. Street or private parking may exist"
    end

    test "Phone label is not shown when phone nil" do
      lot = %{@lot | manager: %{phone: nil, name: "Parking name", website: "www.parking.com"}}
      output = SiteWeb.StopView.render("_parking_lot.html", lot: lot)
      refute safe_to_string(output) =~ "Phone"
    end

    test "Pay by Phone ID is not shown if it doesn't exist" do
      output = SiteWeb.StopView.render("_parking_lot.html", lot: @lot)
      refute safe_to_string(output) =~ "Pay By Phone"
    end

    test "Pay by Phone ID is shown if it does exist" do
      lot = %{@lot | pay_by_phone_id: "1234"}
      output = SiteWeb.StopView.render("_parking_lot.html", lot: lot)
      assert safe_to_string(output) =~ "Pay By Phone"
    end

  end
end
