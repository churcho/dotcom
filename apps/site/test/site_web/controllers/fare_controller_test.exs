defmodule SiteWeb.FareControllerTest do
  use SiteWeb.ConnCase, async: true
  import SiteWeb.FareController
  alias Fares.{Fare, Summary}
  alias SiteWeb.FareController.Filter

  describe "index" do
    test "renders", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert html_response(conn, 200) =~ "Fares and Passes"
    end

    test "includes 4 summarized bus/subway fares", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert [%Summary{}, _, _, _] = conn.assigns.bus_subway
    end

    test "includes summarized Commuter Rail and Ferry fares", %{conn: conn} do
      conn = get conn, fare_path(conn, :index)
      assert [%Summary{}, _] = conn.assigns.commuter_and_ferry
    end
  end

  describe "show" do
    test "renders commuter rail", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, "commuter-rail", origin: "place-sstat", destination: "Readville")
      assert html_response(conn, 200) =~ "Commuter Rail Fares"
    end

    test "renders ferry", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, :ferry, origin: "Boat-Long", destination: "Boat-Logan")
      response = html_response(conn, 200)
      assert response =~ "Ferry Fares"
      assert response =~ "Valid between"
      assert response =~ "Long Wharf"
      assert response =~ "Logan"
    end

    test "renders ferry when no destinations", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, :ferry)
      response = html_response(conn, 200)
      assert response =~ "Find Your Fare"
    end

    test "renders bus/subway", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, "bus-subway")
      assert html_response(conn, 200) =~ "Bus and Subway Fares"
    end

    test "lists vending machine stations on bus/subway page", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, "bus-subway")

      for station <- ["place-north", "place-sstat", "place-bbsta", "place-portr", "place-mlmnl", "Lynn", "Worcester", "place-rugg", "place-forhl", "place-jfk", "place-qnctr", "place-brntn"] do
        assert html_response(conn, 200) =~ station
      end
    end

    test "lists charliecard stations on bus/subway page", %{conn: conn} do
      for station <- ["place-alfcl", "place-armnl", "place-asmnl", "place-bbsta", "64000", "place-forhl", "place-harsq", "place-north", "place-ogmnl", "place-pktrm", "place-rugg"] do
      conn = get conn, fare_path(conn, :show, "bus-subway")
        assert html_response(conn, 200) =~ station
      end
    end

    test "renders a page about retail sale locations", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, "retail-sales-locations")
      assert html_response(conn, 200) =~ "Retail Sales Locations"
    end

    test "404s on nonexistant mode", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, :doesnotexist)
      assert html_response(conn, 404) =~ "Your stop cannot be found."
    end
  end

  describe "fare_sales_locations/2" do
    test "calculates nearest retail_sales_locations" do
      nearby_fn = fn position -> [{%{latitude: position.latitude, longitude: position.longitude}, 10.0}] end

      locations = fare_sales_locations(%{latitude: 42.0, longitude: -71.0}, nearby_fn)
      assert locations == [{%{latitude: 42.0, longitude: -71.0}, 10.0}]
    end

    test "when there is no search position, is an empty list of nearby locations" do
      nearby_fn = fn position -> [{%{latitude: position.latitude, longitude: position.longitude}, 10.0}] end

      locations = fare_sales_locations(%{}, nearby_fn)
      assert locations == []
    end
  end

  describe "calculate_position/2" do
    test "it calculates search position and address" do
      params = %{"location" => %{"address" => "42.0, -71.0"}}
      geocode_fn = fn _address ->
        {:ok, [%GoogleMaps.Geocode.Address{formatted: "address", latitude: 42.0, longitude: -70.1}]}
      end

      {position, formatted} = calculate_position(params, geocode_fn)

      assert formatted == "address"
      assert %{latitude: 42.0, longitude: -70.1} = position
    end

    test "when there is no location map there is no position" do
      params = %{}
      geocode_fn = fn _address -> %{formatted: "address", latitude: 42.0, longitude: -71.0} end
      {position, formatted}  = calculate_position(params, geocode_fn)
      assert formatted == ""
      assert position == %{}
    end
  end

  describe "current_pass/1" do
    test "is the current month when the date given is prior to the 15th" do
      {:ok, date} = Timex.parse("2016-12-01T12:12:12-05:00", "{ISO:Extended}")

      assert current_pass(date) == "December 2016"
    end

    test "is the next month when the date given is the 15th or later" do
      {:ok, date} = Timex.parse("2016-12-15T12:12:12-05:00", "{ISO:Extended}")

      assert current_pass(date) == "January 2017"
    end

    test "uses the date passed in if there is one", %{conn: conn} do
      conn = get conn, fare_path(conn, :show, "retail-sales-locations", date_time: "2013-01-01T12:12:12-05:00")

      assert html_response(conn, 200) =~ "January 2013"
    end
  end

  describe "filter_reduced/2" do
    @fares [%Fare{name: {:zone, "6"}, reduced: nil},
            %Fare{name: {:zone, "5"}, reduced: nil},
            %Fare{name: {:zone, "6"}, reduced: :student}]

    test "filters out non-standard fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: nil},
                        %Fare{name: {:zone, "5"}, reduced: nil}]
      assert filter_reduced(@fares, nil) == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert filter_reduced(@fares, :student) == expected_fares
    end
  end

  describe "selected_filter" do
    @filters [
      %Filter{id: "1"},
      %Filter{id: "2"}
    ]

    test "defaults to returning the first filter" do
      assert selected_filter(@filters, nil) == List.first(@filters)
      assert selected_filter(@filters, "unknown") == List.first(@filters)
    end

    test "returns the filter based on the id" do
      assert selected_filter(@filters, "1") == List.first(@filters)
      assert selected_filter(@filters, "2") == List.last(@filters)
    end

    test "if there are no filters, return nil" do
      assert selected_filter([], "1") == nil
    end
  end

  describe "zone" do
    test "assigns zone fare info", %{conn: conn} do
      conn = get conn, fare_path(conn, :zone)
      assert is_list(conn.assigns[:fare_zone_info])
    end

    test "successfully renders the page", %{conn: conn} do
      conn = get conn, fare_path(conn, :zone)
      assert html_response(conn, 200) =~ "Commuter Rail fares depend on which stops you board and exit the train."
    end
  end
end
