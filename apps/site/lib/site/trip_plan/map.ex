defmodule Site.TripPlan.Map do
  alias TripPlan.{Leg, TransitDetail, Itinerary, NamedPosition}
  alias Util.Position
  alias GoogleMaps.{MapData, MapData.Marker, MapData.Path, MapData.Layers}
  alias Site.MapHelpers
  alias Routes.Route

  @type static_map :: String.t
  @type t :: {MapData.t, static_map}
  @type route_mapper :: (String.t -> Route.t | nil)
  @type stop_mapper :: (String.t -> Stops.Stop.t | nil)

  @default_opts [
    route_mapper: &Routes.Repo.get/1,
    stop_mapper: &Stops.Repo.get/1
  ]

  @moduledoc """
  Handles generating the maps displayed within the TripPlan Controller
  """

  @doc """
  Returns the url for the initial map for the Trip Planner
  """
  @spec initial_map_src() :: static_map
  def initial_map_src do
    {630, 400}
    |> MapData.new(14)
    |> MapData.add_marker(initial_marker())
    |> GoogleMaps.static_map_url()
  end

  def initial_map_data do
    {630, 400}
    |> MapData.new(14)
    |> MapData.add_marker(initial_marker())
    |> MapData.add_layers(%Layers{transit: true})
    |> MapData.auto_init?(false)
  end

  @spec initial_marker() :: Marker.t
  defp initial_marker do
    Marker.new(42.360718, -71.05891, visible?: false)
  end

  @doc """
  Returns the static map data and source URL
  Accepts a function that will return either a
  Route or nil when given a route_id
  """
  @spec itinerary_map(Itinerary.t, Keyword.t) :: t
  def itinerary_map(itinerary, opts \\ []) do
    map_data = itinerary_map_data(itinerary, Keyword.merge(@default_opts, opts))
    {map_data, GoogleMaps.static_map_url(map_data)}
  end

  @spec itinerary_map_data(Itinerary.t, Keyword.t) :: MapData.t
  defp itinerary_map_data(itinerary, opts) do
    markers = markers_for_legs(itinerary, opts)
    paths = Enum.map(itinerary, &build_leg_path(&1, opts[:route_mapper]))

    {600, 600}
    |> MapData.new()
    |> MapData.add_markers(markers)
    |> MapData.add_paths(paths)
    |> MapData.add_layers(%Layers{transit: true})
  end

  @spec build_leg_path(Leg.t, route_mapper) :: Path.t
  defp build_leg_path(leg, route_mapper) do
    color = leg_color(leg, route_mapper)
    path_weight = if Leg.transit?(leg), do: 5, else: 1

    leg.polyline
    |> extend_to_endpoints(leg)
    |> Path.new(color: color, weight: path_weight, dotted?: !Leg.transit?(leg))
  end

  @spec extend_to_endpoints(String.t, Leg.t) :: String.t
  defp extend_to_endpoints(polyline, leg) do
    from = {Position.longitude(leg.from), Position.latitude(leg.from)}
    to = {Position.longitude(leg.to), Position.latitude(leg.to)}

    polyline
    |> Polyline.decode
    |> (fn line -> Enum.concat([[from], line, [to]]) end).()
    |> Polyline.encode
  end

  @spec markers_for_legs(Itinerary.t, Keyword.t) :: [Marker.t]
  defp markers_for_legs(legs, opts) do
    leg_count = Enum.count(legs)
    legs
    |> Enum.zip(Stream.iterate(0, &(&1 + 2)))
    |> Enum.flat_map(&build_marker_for_leg(&1, opts, leg_count))
  end

  @spec build_marker_for_leg({Leg.t, non_neg_integer}, Keyword.t, non_neg_integer) :: [Marker.t]
  defp build_marker_for_leg({leg, idx}, opts, leg_count) do
    route = route_for_leg(leg, opts[:route_mapper])
    leg_positions = [{leg.from, idx}, {leg.to, idx + 1}]
    build_markers_for_leg_positions(leg_positions, route, opts[:stop_mapper], leg_count)
  end

  defp build_markers_for_leg_positions(positions_with_indicies, route, stop_mapper, leg_count) do
    icon_for_index = fn idx -> MapHelpers.map_stop_icon_path(:mid, idx in [0, 2 * leg_count - 1]) end
    for {position, index} <- positions_with_indicies do
      build_marker_for_leg_position(position, route, stop_mapper, icon_for_index.(index))
    end
  end

  @spec build_marker_for_leg_position(NamedPosition.t, Route.t | nil, stop_mapper, String.t) :: Marker.t
  defp build_marker_for_leg_position(leg_position, route, stop_mapper, icon) do
    leg_position
    |> Position.latitude
    |> Marker.new(Position.longitude(leg_position),
                  icon: icon,
                  size: :mid,
                  tooltip: tooltip_for_position(leg_position, stop_mapper),
                  z_index: z_index(route))
  end

  @spec leg_color(Leg.t, route_mapper) :: String.t
  defp leg_color(%Leg{mode: %TransitDetail{route_id: route_id}}, route_mapper) do
    route_id
    |> route_mapper.()
    |> MapHelpers.route_map_color()
  end
  defp leg_color(_leg, _route_mapper) do
    "000000"
  end

  @spec route_for_leg(Leg.t, route_mapper) :: Route.t | nil
  defp route_for_leg(leg, route_mapper) do
    case Leg.route_id(leg) do
      :error -> nil
      {:ok, route_id} -> route_mapper.(route_id)
    end
  end

  @spec tooltip_for_position(NamedPosition.t, stop_mapper) :: String.t
  defp tooltip_for_position(%NamedPosition{stop_id: nil, name: name}, _stop_mapper) do
    name
  end
  defp tooltip_for_position(%NamedPosition{stop_id: stop_id} = position, stop_mapper) do
    case stop_mapper.(stop_id) do
      nil -> position.name
      stop -> stop.name
    end
  end

  @spec z_index(Route.t | nil) :: 0 | 1
  defp z_index(nil), do: 0
  defp z_index(_), do: 1
end
