defmodule SiteWeb.TransitNearMeControllerTest do
  use SiteWeb.ConnCase

  alias GoogleMaps.{Geocode.Address, MapData, MapData.Marker}
  alias Routes.Route
  alias Schedules.Schedule
  alias Site.TransitNearMe
  alias SiteWeb.TransitNearMeController, as: TNMController
  alias Stops.Stop

  @orange_line %{
    id: "Orange",
    description: :rapid_transit,
    name: "Orange Line",
    type: 1,
    href: "/ornage-line"
  }
  @cr_worcester %{
    id: "CR-Worcester",
    description: :commuter_rail,
    name: "Framingham/Worcester Line",
    type: 2,
    href: "/cr-worcester"
  }
  @cr_franklin %{
    id: "CR-Franklin",
    description: :commuter_rail,
    name: "Franklin Line",
    type: 2,
    href: "/cr-franklin"
  }
  @cr_needham %{
    id: "CR-Needham",
    description: :commuter_rail,
    name: "Needham Line",
    type: 2,
    href: "/cr-needham"
  }
  @cr_providence %{
    id: "CR-Providence",
    description: :commuter_rail,
    name: "Providence/Stoughton Line",
    type: 2,
    href: "/cr-providence"
  }
  @bus_10 %{id: "10", description: :local_bus, name: "10", type: 3, href: "/bus-10"}
  @bus_39 %{id: "39", description: :key_bus_route, name: "39", type: 3, href: "/bus-39"}
  @bus_170 %{id: "170", description: :limited_service, name: "170", type: 3, href: "/bus-170"}

  @back_bay %Stop{
    accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
    address: "145 Dartmouth St Boston, MA 02116-5162",
    id: "place-bbsta",
    latitude: 42.34735,
    longitude: -71.075727,
    name: "Back Bay",
    station?: true
  }

  @data %TransitNearMe{
    distances: %{"place-bbsta" => 0.52934802},
    stops: [@back_bay],
    schedules: %{
      "place-bbsta" => [
        %Schedule{stop: @back_bay, route: struct(Route, @orange_line)},
        %Schedule{stop: @back_bay, route: struct(Route, @cr_worcester)},
        %Schedule{stop: @back_bay, route: struct(Route, @cr_franklin)},
        %Schedule{stop: @back_bay, route: struct(Route, @cr_needham)},
        %Schedule{stop: @back_bay, route: struct(Route, @cr_providence)},
        %Schedule{stop: @back_bay, route: struct(Route, @bus_10)},
        %Schedule{stop: @back_bay, route: struct(Route, @bus_39)},
        %Schedule{stop: @back_bay, route: struct(Route, @bus_170)}
      ]
    }
  }

  @stop_with_routes %{
    distance: 0.52934802,
    routes: [
      %{group_name: :orange_line, routes: [@orange_line]},
      %{group_name: :bus, routes: [@bus_39, @bus_170, @bus_10]},
      %{
        group_name: :commuter_rail,
        routes: [@cr_franklin, @cr_needham, @cr_providence, @cr_worcester]
      }
    ],
    stop: @back_bay
  }

  def location_fn(%{"address" => %{"latitude" => "valid", "longitude" => "valid"}}, []) do
    send(self(), :location_fn)

    {:ok,
     [
       %Address{
         latitude: 42.351,
         longitude: -71.066,
         formatted: "10 Park Plaza, Boston, MA, 02116"
       }
     ]}
  end

  def location_fn(%{"address" => %{"latitude" => "no_stops", "longitude" => "no_stops"}}, []) do
    send(self(), :location_fn)

    {:ok,
     [
       %Address{
         latitude: 0.0,
         longitude: 0.0,
         formatted: "no_stops"
       }
     ]}
  end

  def location_fn(%{"address" => %{"latitude" => "no_results", "longitude" => "no_results"}}, []) do
    send(self(), :location_fn)
    {:error, :zero_results}
  end

  def location_fn(%{"address" => %{"latitude" => "error", "longitude" => "error"}}, []) do
    send(self(), :location_fn)
    {:error, :internal_error}
  end

  def location_fn(%{}, []) do
    send(self(), :location_fn)
    :no_address
  end

  def data_fn(
        %Address{formatted: "10 Park Plaza, Boston, MA, 02116"},
        date: %Date{},
        now: %DateTime{}
      ) do
    send(self(), :data_fn)
    @data
  end

  def data_fn(%Address{formatted: "no_stops"}, date: %Date{}, now: %DateTime{}) do
    send(self(), :data_fn)
    %TransitNearMe{}
  end

  def to_json_fn(%TransitNearMe{}, [], now: %DateTime{}) do
    send(self(), :to_json_fn)
    []
  end

  setup do
    conn =
      build_conn()
      |> assign(:location_fn, &location_fn/2)
      |> assign(:data_fn, &data_fn/2)
      |> assign(:to_json_fn, &to_json_fn/3)

    {:ok, conn: conn}
  end

  test "index is under a flag", %{conn: conn} do
    assert conn
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 404

    assert conn
           |> put_req_cookie("transit_near_me_redesign", "true")
           |> get(transit_near_me_path(conn, :index))
           |> Map.fetch!(:status) == 200
  end

  describe "with no location params" do
    test "does not attempt to calculate stops with routes", %{conn: conn} do
      conn =
        conn
        |> put_req_cookie("transit_near_me_redesign", "true")
        |> get(transit_near_me_path(conn, :index))

      assert conn.status == 200

      assert_receive :location_fn
      refute_receive :data_fn

      assert conn.assigns.location == :no_address
      assert conn.assigns.routes_json == []
      assert conn.assigns.stops_json == []
      assert get_flash(conn) == %{}
    end
  end

  describe "with valid location params" do
    test "assigns stops with routes", %{conn: conn} do
      params = %{"address" => %{"latitude" => "valid", "longitude" => "valid"}}

      conn =
        conn
        |> put_req_cookie("transit_near_me_redesign", "true")
        |> get(transit_near_me_path(conn, :index, params))

      assert conn.status == 200

      assert_receive :location_fn
      assert_receive :data_fn
      assert_receive :to_json_fn

      assert {:ok, [%Address{formatted: "10 Park Plaza, Boston, MA, 02116"}]} =
               conn.assigns.location

      assert conn.assigns.routes_json ==
               to_json_fn(%TransitNearMe{}, [], now: conn.assigns.date_time)

      assert conn.assigns.stops_json
      assert %MapData{} = conn.assigns.map_data
      assert Enum.count(conn.assigns.map_data.markers) == 2
      assert %Marker{} = Enum.find(conn.assigns.map_data.markers, &(&1.id == "current-location"))

      assert %Marker{} =
               Enum.find(conn.assigns.map_data.markers, &(&1.id == @stop_with_routes.stop.id))

      assert get_flash(conn) == %{}
    end

    test "flashes an error if location has no stops nearby", %{conn: conn} do
      params = %{"address" => %{"latitude" => "no_stops", "longitude" => "no_stops"}}

      conn =
        conn
        |> put_req_cookie("transit_near_me_redesign", "true")
        |> get(transit_near_me_path(conn, :index, params))

      assert conn.status == 200

      assert_receive :location_fn
      assert_receive :data_fn

      assert {:ok, [%Address{formatted: "no_stops"}]} = conn.assigns.location
      assert conn.assigns.routes_json == []
      assert conn.assigns.stops_json == []

      assert get_flash(conn) == %{
               "info" => %SiteWeb.PartialView.FullscreenError{
                 body:
                   "There doesn't seem to be any stations found near the given address. Please try a different address to continue.",
                 heading: "No MBTA service nearby"
               }
             }
    end
  end

  describe "with invalid location params" do
    test "flashes an error when address cannot be located", %{conn: conn} do
      params = %{"address" => %{"latitude" => "no_results", "longitude" => "no_results"}}

      conn =
        conn
        |> put_req_cookie("transit_near_me_redesign", "true")
        |> get(transit_near_me_path(conn, :index, params))

      assert conn.status == 200

      assert_receive :location_fn
      refute_receive :data_fn

      assert conn.assigns.location == {:error, :zero_results}
      assert conn.assigns.routes_json == []
      assert conn.assigns.stops_json == []

      assert get_flash(conn) == %{
               "info" => %SiteWeb.PartialView.FullscreenError{
                 body: "We are unable to locate that address.",
                 heading: "We’re sorry"
               }
             }
    end

    test "flashes an error for any other error", %{conn: conn} do
      params = %{"address" => %{"latitude" => "error", "longitude" => "error"}}

      conn =
        conn
        |> put_req_cookie("transit_near_me_redesign", "true")
        |> get(transit_near_me_path(conn, :index, params))

      assert conn.status == 200

      assert_receive :location_fn
      refute_receive :data_fn

      assert conn.assigns.location == {:error, :internal_error}
      assert conn.assigns.stops_json == []
      assert conn.assigns.routes_json == []

      assert get_flash(conn) == %{
               "info" => %SiteWeb.PartialView.FullscreenError{
                 body: "There was an error locating that address. Please try again.",
                 heading: "We’re sorry"
               }
             }
    end
  end

  describe "assign_map_data/1" do
    test "initializes a map with no markers", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_json, [])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert conn.assigns.map_data.markers == []
    end

    test "assigns a marker for all stops", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_json, [@stop_with_routes])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert [marker] = conn.assigns.map_data.markers
      assert %Marker{} = marker
      assert marker.latitude == @stop_with_routes.stop.latitude
      assert marker.longitude == @stop_with_routes.stop.longitude
      assert marker.tooltip =~ "c-location-card__name"
    end

    test "assigns a marker with a bus icon for stops that aren't stations", %{conn: conn} do
      bus_stop_with_routes =
        put_in(
          @stop_with_routes.routes,
          [
            %{
              group_name: :bus,
              routes: [
                %{
                  custom_route?: false,
                  description: :key_bus_route,
                  direction_destinations: :unknown,
                  direction_names: %{"0" => "Outbound", "1" => "Inbound"},
                  id: "39",
                  long_name: "",
                  name: "39",
                  type: 3,
                  href: "/39"
                },
                %{
                  custom_route?: false,
                  description: :limited_service,
                  direction_destinations: :unknown,
                  direction_names: %{"0" => "Outbound", "1" => "Inbound"},
                  id: "170",
                  long_name: "",
                  name: "170",
                  type: 3,
                  href: "/170"
                },
                %{
                  custom_route?: false,
                  description: :local_bus,
                  direction_destinations: :unknown,
                  direction_names: %{"0" => "Outbound", "1" => "Inbound"},
                  id: "10",
                  long_name: "",
                  name: "10",
                  type: 3,
                  href: "/10"
                }
              ]
            }
          ]
        )

      conn =
        conn
        |> assign(:stops_json, [@stop_with_routes, bus_stop_with_routes])
        |> assign(:location, nil)
        |> TNMController.assign_map_data()

      assert %MapData{} = conn.assigns.map_data
      assert [_, bus_marker] = conn.assigns.map_data.markers
      assert %Marker{} = bus_marker
      assert bus_marker.icon == "map-stop-marker"
    end

    test "assigns a marker for the provided location", %{conn: conn} do
      conn =
        conn
        |> assign(:stops_json, [])
        |> assign(
          :location,
          {:ok,
           [
             %Address{
               formatted: "10 Park Plaza",
               latitude: @stop_with_routes.stop.latitude,
               longitude: @stop_with_routes.stop.longitude
             }
           ]}
        )
        |> TNMController.assign_map_data()

      assert [marker] = conn.assigns.map_data.markers
      assert marker.id == "current-location"
      assert marker.tooltip == "10 Park Plaza"
    end
  end
end
