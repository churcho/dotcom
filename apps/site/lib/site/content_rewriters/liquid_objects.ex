defmodule Site.ContentRewriters.LiquidObjects do
  @moduledoc """

  This module handles so-called "liquid objects": content appearing between
  {{ and }} in text. The wrapping braces should be removed and the text inside
  should be stripped before being given to this module.

  """

  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  import SiteWeb.ContentView, only: [svg_icon_with_circle: 1]

  alias Site.Components.Icons.SvgIconWithCircle

  @available_fare_replacements [
    "subway:charlie_card",
    "subway:cash",
    "bus:charlie_card",
    "bus:cash",
  ]

  @doc "Replace fa- prefixed objects with corresponding fa() call"
  @spec replace(String.t) :: String.t
  def replace("fa " <> icon) do
    font_awesome_replace(icon)
  end
  def replace("mbta-circle-icon " <> icon) do
    mbta_svg_icon_replace(icon)
  end
  def replace("fare:" <> filters) when filters in @available_fare_replacements do
    filters
    |> fare_filter
    |> Fares.Repo.all
    |> List.first
    |> Fares.Format.price
  end
  def replace(unmatched) do
    "{{ #{unmatched} }}"
  end

  defp font_awesome_replace(icon) do
    icon
    |> get_arg
    |> SiteWeb.ViewHelpers.fa
    |> safe_to_string
  end

  defp mbta_svg_icon_replace(icon) do
    icon
    |> get_arg
    |> mbta_svg_icon
    |> safe_to_string
  end

  defp get_arg(str) do
    str
    |> String.replace("\"", "")
    |> String.trim
  end

  defp mbta_svg_icon("commuter-rail"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :commuter_rail})
  defp mbta_svg_icon("subway"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :subway})
  defp mbta_svg_icon("bus"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :bus})
  defp mbta_svg_icon("ferry"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :ferry})
  defp mbta_svg_icon("t-logo"), do: svg_icon_with_circle(%SvgIconWithCircle{icon: :t_logo, class: "icon-boring"})
  defp mbta_svg_icon(unknown), do: raw(~s({{ mbta-circle-icon "#{unknown}" }}))

  defp fare_filter("subway:charlie_card"), do: [mode: :subway, includes_media: :charlie_card, duration: :single_trip]
  defp fare_filter("subway:cash"), do: [mode: :subway, includes_media: :cash, duration: :single_trip]
  defp fare_filter("bus:charlie_card"), do: [name: :local_bus, includes_media: :charlie_card, duration: :single_trip]
  defp fare_filter("bus:cash"), do: [name: :local_bus, includes_media: :cash, duration: :single_trip]
end
