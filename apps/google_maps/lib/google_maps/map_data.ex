defmodule GoogleMaps.MapData do
  alias GoogleMaps.MapData.Path
  alias GoogleMaps.MapData.Marker
  alias GoogleMaps.MapData.Layers

  @moduledoc """
  Represents the data required to build a a google map.
  """
  @default_dynamic_options %{gestureHandling: "cooperative"}

  @type lat_lng :: %{latitude: float, longitude: float}

  defstruct [
    default_center: %{latitude: 42.360718, longitude: -71.05891},
    markers: [],
    paths: [],
    width: 0,
    height: 0,
    zoom: nil,
    scale: 1,
    dynamic_options: @default_dynamic_options,
    layers: %Layers{},
    auto_init: true
  ]

  @type t :: %__MODULE__{
    default_center: lat_lng,
    markers: [Marker.t],
    paths: [Path.t],
    width: integer,
    height: integer,
    zoom: integer | nil,
    scale: 1 | 2,
    dynamic_options: %{atom => String.t | boolean},
    layers: Layers.t,
    auto_init: boolean
  }

  @typep static_query_key :: :markers | :path | :zoom | :scale | :center | :size
  @typep query_entry :: {static_query_key, String.t | nil}

  @doc """
  Given a MapData stuct, returns a Keyword list representing
  a static query.
  """
  @spec static_query(t) :: [query_entry]
  def static_query(map_data) do
    [
      center: center_value(map_data),
      size: size_value(map_data),
      scale: map_data.scale,
      zoom: map_data.zoom,
    ]
    |> format_static_markers(map_data.markers)
    |> format_static_paths(map_data.paths)
  end

  @spec new({integer, integer}, integer | nil, 1 | 2) :: t
  def new({width, height}, zoom \\ nil, scale \\ 1) do
    %__MODULE__{
      width: width,
      height: height,
      zoom: zoom,
      scale: scale
    }
  end

  @spec auto_init?(t, boolean) :: t
  def auto_init?(map_data, auto_init) do
    %{map_data | auto_init: auto_init}
  end

  @doc """
  Returns a new MapData struct where the given marker is appended
  to the current list of markers
  """
  @spec add_marker(t, Marker.t) :: t
  def add_marker(map_data, marker) do
    %{map_data | markers: [marker | map_data.markers]}
  end

  @doc """
  Returns a new MapData struct where the given markers are appended
  to the current list of markers
  """
  @spec add_markers(t, [Marker.t]) :: t
  def add_markers(map_data, markers) do
    %{map_data | markers: Enum.concat(map_data.markers, markers)}
  end

  @doc """
  Returns a new MapData struct where the given path is appended
  to the current list of paths
  """
  @spec add_path(t, Path.t) :: t
  def add_path(map_data, path) do
    %{map_data | paths: [path | map_data.paths]}
  end

  @doc """
  Returns a new MapData struct where the given paths are appended
  to the current list of paths
  """
  @spec add_paths(t, [Path.t]) :: t
  def add_paths(map_data, paths) do
    %{map_data | paths: Enum.concat(map_data.paths, paths)}
  end

  @doc """
  Enable or disable layers on the map.
  """
  @spec add_layers(t, Layers.t) :: t
  def add_layers(%__MODULE__{} = map_data, %Layers{} = layers) do
    %{map_data | layers: layers}
  end

  @doc """
  Adds params that will disable the streetViewControl
  and MapTypeControl on a dynamic map.
  """
  @spec disable_map_type_controls(t) :: t
  def disable_map_type_controls(map_data) do
    opts_map = %{streetViewControl: false, mapTypeControl: false}
    %{map_data | dynamic_options: Map.merge(map_data.dynamic_options, opts_map)}
  end

  @spec center_value(t) :: String.t | nil
  defp center_value(map_data) do
    do_center_value(map_data, Enum.any?(map_data.markers, & &1.visible?))
  end

  @spec do_center_value(t, boolean) :: String.t | nil
  defp do_center_value(%__MODULE__{markers: [marker | _]}, false) do
    Marker.format_static_marker(marker)
  end
  defp do_center_value(_map_data, _all_hiden), do: nil

  @spec size_value(t) :: String.t
  defp size_value(%__MODULE__{width: width, height: height}), do: "#{width}x#{height}"

  @doc """
  Formats a list of Markers. Markers are grouped by icon.
  """
  @spec format_static_markers(Keyword.t, [Marker.t]) :: Keyword.t
  def format_static_markers(params, markers) do
    markers
    |> Enum.filter(& &1.visible?)
    |> Enum.group_by(& &1.icon)
    |> Enum.map(&do_format_static_markers/1)
    |> add_values_for_key(:markers, params)
  end

  @spec do_format_static_markers({String.t | nil, [Marker.t]}) :: String.t
  defp do_format_static_markers({nil, markers}) do
    formatted_markers = Enum.map(markers, &Marker.format_static_marker/1)
    "anchor:center|#{Enum.join(formatted_markers, "|")}"
  end
  defp do_format_static_markers({icon, markers}) do
    formatted_markers = Enum.map(markers, &Marker.format_static_marker/1)
    "anchor:center|icon:#{icon}|#{Enum.join(formatted_markers, "|")}"
  end

  @spec format_static_paths([query_entry], [Path.t]) :: [query_entry]
  defp format_static_paths(params, paths) do
    paths
    |> Enum.map(&Path.format_static_path/1)
    |> add_values_for_key(:path, params)
  end

  defp add_values_for_key(values, key, params) do
    Enum.reduce(values, params, fn(value, key_list) -> [{key, value} | key_list] end)
  end
end
