defmodule Site.ServiceNearMeController do
  use Site.Web, :controller
  alias Routes.Route
  alias Stops.Stop

  @doc """
    Handles GET requests both with and without parameters. Calling with an address parameter (String.t) will assign
    make available to the view:
        @stops_with_routes :: [%{stop: %Stops.Stop{}, routes: [%Route{}]}]
  """
  def index(conn, %{"location" => %{"address" => address}}) do
    results = address
    |> GoogleMaps.Geocode.geocode

    results
    |> get_stops_nearby(conn)
    |> stops_with_routes
    |> send_response(conn, address(results))
  end
  def index(conn, _) do
    send_response([], conn)
  end

  #TODO handle differently when multiple results are returned?
  @doc """
    Retrieves stops close to a location and parses into the correct configuration
  """
  @spec get_stops_nearby(GoogleMaps.Geocode.t, Plug.Conn.t) :: [Stop.t]
  def get_stops_nearby({:ok, [location | _]},
                       %{private: private}) do
    private
    |> Map.get(:nearby_stops, &Stops.Nearby.nearby/1)
    |> Kernel.apply([location])
  end
  def get_stops_nearby({:ok, []}, _conn), do: []
  def get_stops_nearby({:error, _error_code, _error_str}, _conn), do: []


  @spec stops_with_routes([Stop.t]) :: [%{stop: Stop.t, routes: [Route.t]}]
  def stops_with_routes(stops) do
    stops
    |> Enum.map(fn stop ->
      %{stop: stop, routes: stop.id |> Routes.Repo.by_stop |> get_route_groups}
    end)
  end

  @spec get_route_groups([Route.t]) :: [Routes.Group.t]
  def get_route_groups(route_list) do
    route_list
    |> Routes.Group.group
    |> separate_subway_lines
    |> Keyword.delete(:subway)
  end


  @doc """
    Returns the grouped routes list with subway lines elevated to the top level, eg:

      separate_subway_lines([commuter: [_], bus: [_], subway: [orange_line, red_line])
      # =>   [commuter: [commuter_lines], bus: [bus_lines], orange: [orange_line], red: [red_line]]

  """
  @spec separate_subway_lines([Routes.Group.t]) :: [{Routes.Route.gtfs_route_type | Route.subway_lines_type, [Route.t]}]
  def separate_subway_lines([{:subway, subway_lines}|_] = routes) do
    subway_lines
    |> Enum.reduce(routes, &subway_reducer/2)
    # |> Keyword.delete(:subway)
  end
  def separate_subway_lines(routes), do: routes


  @spec subway_reducer(Route.t, [Routes.Group.t]) :: [{Routes.Route.subway_lines_type, [Route.t]}]
  defp subway_reducer(%Route{id: id, type: 1} = route, routes) do
    Keyword.put(routes, id |> Kernel.<>("_line") |> String.downcase |> String.to_atom, [route])
  end
  defp subway_reducer(%Route{name: "Green" <> _} = route, routes) do
    Keyword.put(routes, :green_line, [route])
  end
  defp subway_reducer(%Route{id: "Mattapan"} = route, routes) do
    Keyword.put(routes, :red_line, [route])
  end

  @spec send_response([%{stop: Stop.t, routes: [Routes.Group.t]}], Plug.Conn.t, String.t) :: Plug.Conn.t
  defp send_response(stops_with_routes, conn, address \\ "") do
    conn
    |> assign(:stops_with_routes, stops_with_routes)
    |> assign(:address, address)
    |> flash_if_error(stops_with_routes)
    |> render("index.html", breadcrumbs: ["Service Near Me"])
  end

  @spec flash_if_error(Plug.Conn.t, [%{stop: Stop.t, routes: [Routes.Group.t]}]) :: Plug.Conn.t
  defp flash_if_error(%Plug.Conn{params: %{"location" => %{"address" => ""}}} = conn, []) do
    put_flash(conn, :info, "No address provided. Please try again.")
  end
  defp flash_if_error(%Plug.Conn{params: %{"location" => %{"address" => _addr}}} = conn, []) do
    put_flash(conn, :info, "No stations found near given address.")
  end
  defp flash_if_error(conn, _routes), do: conn

  def address({:ok, [%{formatted: address} | _]}) do
    address
  end
  def address(_), do: ""
end
