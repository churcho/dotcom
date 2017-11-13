defmodule SiteWeb.ScheduleV2ViewTest do
  use SiteWeb.ConnCase, async: true

  alias Schedules.Trip
  alias Stops.{Stop, RouteStop}
  import SiteWeb.ScheduleV2View
  import Phoenix.HTML, only: [safe_to_string: 1]

  @trip %Schedules.Trip{name: "101", headsign: "Headsign", direction_id: 0, id: "1"}
  @stop %Stops.Stop{id: "stop-id", name: "Stop Name"}
  @route %Routes.Route{type: 3, id: "1"}
  @prediction %Predictions.Prediction{departing?: true, direction_id: 0, status: "On Time", trip: @trip}
  @schedule %Schedules.Schedule{
    route: @route,
    trip: @trip,
    stop: @stop
  }
  @vehicle %Vehicles.Vehicle{direction_id: 0, id: "1819", status: :stopped, route_id: @route.id}
  @predicted_schedule %PredictedSchedule{prediction: @prediction, schedule: @schedule}
  @trip_info %TripInfo{
    route: @route,
    vehicle: @vehicle,
    vehicle_stop_name: @stop.name,
    times: [@predicted_schedule],
  }
  @vehicle_tooltip %VehicleTooltip{
    prediction: @prediction,
    vehicle: @vehicle,
    route: @route,
    trip: @trip,
    stop_name: @stop.name
  }

  describe "display_direction/1" do
    test "given no schedules, returns no content" do
      assert display_direction(%JourneyList{}) == ""
    end

    test "given a non-empty list of predicted_schedules, displays the direction of the first one's route" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}}
      trip = %Trip{direction_id: 1}
      journeys = JourneyList.build(
        [%Schedules.Schedule{route: route, trip: trip, stop: %Stop{id: "stop"}}],
        [],
        :last_trip_and_upcoming,
        true,
        origin_id: "stop",
        current_time: ~N[2017-01-01T06:30:00]
      )
      assert journeys |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end

    test "uses predictions if no schedule are available (as on subways)" do
      route = %Routes.Route{direction_names: %{1 => "Northbound"}, id: "1"}
      stop = %Stop{id: "stop"}
      now = Timex.now
      journeys = JourneyList.build_predictions_only(
        [],
        [%Predictions.Prediction{route: route, stop: stop, trip: nil, direction_id: 1,
                                                                      time: Timex.shift(now, hours: -1)}],
        stop.id,
        nil
      )
      assert journeys |> display_direction |> IO.iodata_to_binary == "Northbound to"
    end
  end

  describe "template_for_tab/1" do
    test "returns the template corresponding to a tab value" do
      assert template_for_tab("trip-view") == "_trip_view.html"
      assert template_for_tab("timetable") == "_timetable.html"
    end
  end

  describe "reverse_direction_opts/4" do
    test "reverses direction when the stop exists in the other direction" do
      expected = [trip: nil, direction_id: "1", destination: "place-harsq", origin: "place-davis"]
      actual = reverse_direction_opts(%Stops.Stop{id: "place-harsq"}, %Stops.Stop{id: "place-davis"}, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end

    test "reverses direction when origin and destination aren't selected" do
      expected = [trip: nil, direction_id: "1", destination: nil, origin: nil]
      actual = reverse_direction_opts(nil, nil, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end

    test "maintains origin when there's no destination selected" do
      expected = [trip: nil, direction_id: "1", destination: nil, origin: "place-davis"]
      actual = reverse_direction_opts(%Stops.Stop{id: "place-davis"}, nil, "1")
      assert Enum.sort(expected) == Enum.sort(actual)
    end
  end

  describe "_trip_view.html" do
    test "renders a message if no scheduled trips", %{conn: conn} do
      conn = conn
      |> assign(:all_stops, [])
      |> assign(:date, ~D[2017-01-01])
      |> assign(:destination, nil)
      |> assign(:origin, nil)
      |> assign(:route, %Routes.Route{})
      |> assign(:direction_id, 1)
      |> assign(:show_date_select?, false)
      |> assign(:headsigns, %{0 => [], 1 => []})
      |> fetch_query_params

      output = SiteWeb.ScheduleV2View.render(
        "_trip_view.html",
        Keyword.merge(Keyword.new(conn.assigns), conn: conn)
      ) |> safe_to_string

      assert output =~ "There are no scheduled inbound trips on January 1, 2017."
    end
  end

  describe "_frequency.html" do
    test "renders a no service message if the block doesn't have service" do
      frequency_table = %Schedules.FrequencyList{frequencies: [%Schedules.Frequency{time_block: :am_rush}]}
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = SiteWeb.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date,
        origin: %{name: "Name"},
        route: %Routes.Route{id: "1", type: 3, name: "1"})
      output = safe_to_string(safe_output)
      assert output =~ "No service between these hours"
    end

    test "renders a headway if the block has service" do
      frequency = %Schedules.Frequency{time_block: :am_rush, min_headway: 5, max_headway: 10}
      frequency_table = %Schedules.FrequencyList{frequencies: [frequency]}
      schedules = [%Schedules.Schedule{time: Util.now}]
      date = Util.service_date
      safe_output = SiteWeb.ScheduleV2View.render(
        "_frequency.html",
        frequency_table: frequency_table,
        schedules: schedules,
        date: date,
        origin: %{name: "Name"},
        route: %Routes.Route{id: "1", type: 3, name: "1"})
      output = safe_to_string(safe_output)
      assert output =~ "5-10"
    end
  end


  describe "_trip_info.html" do
    test "make sure page reflects information from full_status function", %{conn: conn} do
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{
        route: route,
        vehicle: %Vehicles.Vehicle{status: :incoming},
        vehicle_stop_name: "Readville"
      }
      actual = SiteWeb.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: nil,
        destination: nil,
        direction_id: 0,
        conn: conn,
        route: route,
        expanded: nil
      )
      expected = TripInfo.full_status(trip_info) |> IO.iodata_to_binary
      assert safe_to_string(actual) =~ expected
    end

    test "the fare link has the same origin and destination params as the page", %{conn: conn} do
      origin = %Stop{id: "place-north"}
      destination = %Stop{id: "Fitchburg"}
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{route: route, base_fare: %Fares.Fare{}}

      actual = SiteWeb.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: origin,
        destination: destination,
        direction_id: 0,
        route: route,
        conn: conn,
        expanded: nil
      )
      assert safe_to_string(actual) =~ "/fares/commuter_rail?destination=Fitchburg&amp;origin=place-north"
    end

    test "the fare description is Round trip fare if it's a round-trip fare", %{conn: conn} do
      origin = %Stop{id: "place-south"}
      destination = %Stop{id: "Foxboro"}
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{route: route, base_fare: %Fares.Fare{duration: :round_trip}}

      actual = SiteWeb.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: origin,
        destination: destination,
        direction_id: 0,
        route: route,
        conn: conn,
        expanded: nil
      )
      assert safe_to_string(actual) =~ "Round trip fare:"
    end

    test "no fare information is rendered without a fare", %{conn: conn} do
      origin = %Stop{id: "place-south"}
      destination = %Stop{id: "Foxboro"}
      route = %Routes.Route{type: 2}
      trip_info = %TripInfo{route: route, base_fare: nil}

      actual = SiteWeb.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: origin,
        destination: destination,
        direction_id: 0,
        route: route,
        conn: conn,
        expanded: nil
      )
      rendered = safe_to_string(actual)
      refute rendered =~ "fare"
    end

    test "a branch is expanded if the expanded param is the branch name", %{conn: conn} do
      origin = %Stop{id: "place-south"}
      destination = %Stop{id: "Foxboro"}
      route = %Routes.Route{type: 2, name: "Franklin Line"}
      trip_info = %TripInfo{route: route, base_fare: nil}

      actual = SiteWeb.ScheduleV2View.render(
        "_trip_info.html",
        trip_info: trip_info,
        origin: origin,
        destination: destination,
        direction_id: 0,
        route: route,
        conn: conn,
        expanded: "Franklin Line"
      )
      rendered = safe_to_string(actual)
      trip_info = Floki.find(rendered, "#trip-info-stops")

      assert Floki.attribute(trip_info, "class") == ["collapse in stop-list"]
    end
  end

  describe "render_trip_info_stops" do
    @assigns %{
      direction_id: 0,
      route: @route,
      conn: %Plug.Conn{},
      vehicle_tooltips: %{{@trip.id, @stop.id} => @vehicle_tooltip},
      trip_info: @trip_info,
      all_alerts: [Alerts.Alert.new(informed_entity: [%Alerts.InformedEntity{
        route: @route.id,
        direction_id: 0,
        stop: @stop.id
      }])]
    }

    test "real time icon shown when prediction is available" do
      output =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> List.first
        |> safe_to_string
      assert output =~ "icon-realtime"
    end

    test "Alert icon is shown when alerts are not empty" do
      output =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert output =~ "icon-alert"
    end

    test "Alert icon is shown with tooltip attributes" do
      output =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary
      assert [alert] = output |> Floki.find(".icon-alert")
      assert Floki.attribute(alert, "data-toggle") == ["tooltip"]
      assert Floki.attribute(alert, "title") == ["Service alert or delay"]
    end

    test "shows vehicle icon when vehicle location is available" do
      output =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert [_vehicle] = output |> Floki.find(".vehicle-bubble")
    end

    test "collapsed stops do not use dotted line" do
      html =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.empty?(Floki.find(html, ".route-branch-stop-bubble.stop.dotted"))
    end

    test "does not show dotted line for last stop when collapse is nil" do
      html =
        [@predicted_schedule]
        |> SiteWeb.ScheduleV2View.render_trip_info_stops(@assigns)
        |> Enum.map(&safe_to_string/1)
        |> IO.iodata_to_binary

      assert Enum.count(Floki.find(html, ".route-branch-stop-bubble.stop.dotted")) == 0
    end
  end

  describe "_line.html" do
    @shape %Routes.Shape{id: "test", name: "test", stop_ids: [], direction_id: 0}
    @hours_of_operation %{
      saturday: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      },
      sunday: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      },
      week: %{
        0 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]},
        1 => %Schedules.Departures{first_departure: ~D[2017-01-01], last_departure: ~D[2017-01-01]}
      }
    }

    test "Bus line with variant filter", %{conn: conn} do
      route_stop_1 = %RouteStop{id: "stop 1", name: "Stop 1", zone: "1", stop_features: []}
      route_stop_2 = %RouteStop{id: "stop 2", name: "Stop 2", zone: "2", stop_features: []}
      output = SiteWeb.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [{[{nil, :terminus}], route_stop_1},
                          {[{nil, :terminus}], route_stop_2}],
              route_shapes: [@shape, @shape],
              active_shape: @shape,
              expanded: nil,
              show_variant_selector: true,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{branch: nil, stops: [route_stop_1,
                                                                route_stop_2]}],
              origin: nil,
              destination: nil,
              direction_id: 1,
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              direction_id: 1,
              reverse_direction_all_stops: [],
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})

      assert safe_to_string(output) =~ "shape-filter"
    end

    test "Bus line without variant filter", %{conn: conn} do
      route_stop_1 = %RouteStop{id: "stop 1", name: "Stop 1", zone: "1", stop_features: []}
      route_stop_2 = %RouteStop{id: "stop 2", name: "Stop 2", zone: "2", stop_features: []}
      output = SiteWeb.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [{[{nil, :terminus}], route_stop_1},
                          {[{nil, :terminus}], route_stop_2}],
              route_shapes: [@shape],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{
                          branch: nil,
                          stops: [route_stop_1,
                                  route_stop_2]}],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              reverse_direction_all_stops: [],
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})

      refute safe_to_string(output) =~ "shape-filter"
    end

    test "does not crash if hours of operation isn't set", %{conn: conn} do
      output = SiteWeb.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [],
              route_shapes: [],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              holidays: [],
              branches: [],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              reverse_direction_all_stops: [],
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})
      refute safe_to_string(output) =~ "Hours of Operation"
    end

    test "Displays error message when there are no trips in selected direction", %{conn: conn} do
      output = SiteWeb.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [],
              route_shapes: [],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              holidays: [],
              branches: [],
              route: %Routes.Route{type: 3},
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              reverse_direction_all_stops: [],
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})
      assert safe_to_string(output) =~ "There are no scheduled"
    end

    test "Doesn't link to last stop if it's excluded", %{conn: conn} do
      route = %Routes.Route{id: "route", type: 3}
      route_stop = %RouteStop{id: "last", name: "last", zone: "1",
                              route: route,
                              stop_features: [], is_terminus?: true, is_beginning?: false}
      output = SiteWeb.ScheduleV2View.render(
              "_line.html",
              conn: Plug.Conn.fetch_query_params(conn),
              stop_list_template: "_stop_list.html",
              all_stops: [{[{nil, :terminus}], route_stop}],
              route_shapes: [@shape],
              expanded: nil,
              active_shape: nil,
              map_img_src: nil,
              hours_of_operation: @hours_of_operation,
              holidays: [],
              branches: [%Stops.RouteStops{
                          branch: nil,
                          stops: [route_stop]}],
              route: route,
              date: ~D[2017-01-01],
              destination: nil,
              origin: nil,
              direction_id: 1,
              reverse_direction_all_stops: [%Stops.Stop{id: "last"}],
              show_date_select?: false,
              headsigns: %{0 => [], 1 => []},
              vehicle_tooltips: %{},
              dynamic_map_data: %{})
      refute safe_to_string(output) =~ trip_view_path(SiteWeb.Endpoint, :show, "route", origin: "last", direction_id: 0)
    end
  end

  describe "no_trips_message/5" do
    test "when a no service error is provided" do
      error = [%JsonApi.Error{code: "no_service", meta: %{"version" => "Spring 2017 version 3D"}}]
      result = no_trips_message(error, nil, nil, nil, ~D[2017-01-01])
      assert IO.iodata_to_binary(result) == "January 1, 2017 is not part of the Spring schedule."
    end
    test "when a starting and ending stop are provided" do
      result = no_trips_message(nil, %Stops.Stop{name: "The Start"}, %Stops.Stop{name: "The End"}, nil, ~D[2017-03-05])
      assert IO.iodata_to_binary(result) == "There are no scheduled trips between The Start and The End on March 5, 2017."
    end

    test "when a direction is provided" do
      result = no_trips_message(nil, nil, nil, "Inbound", ~D[2017-03-05])
      assert IO.iodata_to_binary(result) == "There are no scheduled inbound trips on March 5, 2017."
    end

    test "fallback when nothing is available" do
      result = no_trips_message(nil, nil, nil, nil, nil)
      assert IO.iodata_to_binary(result) == "There are no scheduled trips."
    end

    test "does not downcase non-traditional directions" do
      error = origin = destination = nil
      direction = "TF Green Airport" # CR-Foxboro
      date = ~D[2017-11-01]
      result = no_trips_message(error, origin, destination, direction, date)
      assert IO.iodata_to_binary(result) == "There are no scheduled TF Green Airport trips on November 1, 2017."
    end
  end

  describe "route_pdf_link/3" do
    test "returns an empty list if no PDF for that route" do
      rendered = safe_to_string(route_pdf_link([], %Routes.Route{}, ~D[2018-01-01]))
      assert {"div", _, []} = Floki.parse(rendered)
    end

    test "shows all PDFs for the route" do
      route_pdfs = [
        %Content.RoutePdf{path: "/basic-current-url", date_start: ~D[2017-12-01]},
        %Content.RoutePdf{path: "/basic-future-url", date_start: ~D[2018-02-01]},
        %Content.RoutePdf{path: "/custom-url", date_start: ~D[2017-12-01], link_text_override: "custom text"},
      ]
      route = %Routes.Route{name: "1", type: 3}
      rendered = safe_to_string(route_pdf_link(route_pdfs, route, ~D[2018-01-01]))
      assert rendered =~ "View PDF of Route 1 paper schedule"
      assert rendered =~ "basic-current-url"
      assert rendered =~ "View PDF of custom text"
      assert rendered =~ "View PDF of upcoming schedule — effective Feb 1"
      assert rendered =~ "http://" # full URL
    end

    test "considers PDFs that start today as current" do
      route_pdfs = [%Content.RoutePdf{path: "/url", date_start: ~D[2018-01-01]}]
      route = %Routes.Route{name: "1", type: 3}
      rendered = safe_to_string(route_pdf_link(route_pdfs, route, ~D[2018-01-01]))
      assert rendered =~ "View PDF of Route 1 paper schedule"
    end
  end

  describe "pretty_route_name/1" do
    test "has correct text for bus routes" do
      route = %Routes.Route{id: "741", name: "SL1", type: 3}
      assert pretty_route_name(route) == "Route SL1"
    end

    test "has correct name for subway" do
      route = %Routes.Route{id: "Red", name: "Red Line", type: 1}
      assert pretty_route_name(route) == "Red line"
    end

    test "has correct name for ferries" do
      route = %Routes.Route{id: "Boat-F4", name: "Charlestown Ferry", type: 1}
      assert pretty_route_name(route) == "Charlestown ferry"
    end

    test "has correct name for mattapan" do
      route = %Routes.Route{id: "Mattapan", name: "Mattapan Trolley", type: 1}
      assert pretty_route_name(route) == "Mattapan trolley"
    end

    test "allows line break after slash" do
      route = %Routes.Route{id: "CR-Worcester", name: "Framingham/Worcester Line", type: 1}
      # expected result has a zero-width space bewtween / and W
      assert pretty_route_name(route) == "Framingham/​Worcester line"
    end
  end

  describe "_empty.html" do
    @date ~D[2016-01-01]

    test "shows date reset link when not current date", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = SiteWeb.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: "origin",
                                            destination: "dest",
                                            direction: "inbound",
                                            date: @date,
                                            conn: conn)
      assert safe_to_string(rendered) =~ "View inbound trips"
    end

    test "Does not show reset link if selected date is service date", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = SiteWeb.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: "origin",
                                            destination: "dest",
                                            direction: "inbound",
                                            date: Util.service_date(),
                                            conn: conn)
      refute safe_to_string(rendered) =~ "View inbound trips"
    end

    test "Does not list date if none is given", %{conn: conn} do
      conn = %{conn | query_params: %{}}
      rendered = SiteWeb.ScheduleV2View.render("_empty.html",
                                            error: nil,
                                            origin: nil,
                                            destination: nil,
                                            direction: "inbound",
                                            date: nil,
                                            conn: conn)
      refute safe_to_string(rendered) =~ "on"
      assert safe_to_string(rendered) =~ "There are no scheduled inbound"
    end
  end

  describe "get expected column width in each use case" do
    test "forced 6 column" do
      assert direction_select_column_width(true, 40) == 6
    end

    test "long headsign column" do
      assert direction_select_column_width(nil, 40) == 8
    end

    test "short headsign column" do
      assert direction_select_column_width(false, 10) == 4
    end
  end

  describe "fare_params/2" do
    @origin %Stop{id: "place-north"}
    @destination %Stop{id: "Fitchburg"}

    test "fare link when no origin/destination chosen" do
      assert fare_params(nil, nil) == %{}
    end

    test "fare link when only origin chosen" do
      assert fare_params(@origin, nil) == %{origin: @origin}
    end

    test "fare link when origin and destination chosen" do
      assert fare_params(@origin, @destination) == %{origin: @origin, destination: @destination}
    end
  end
end
