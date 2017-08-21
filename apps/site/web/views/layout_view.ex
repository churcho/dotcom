defmodule Site.LayoutView do
  use Site.Web, :view
  import Util.BreadcrumbHTML, only: [breadcrumb_trail: 1, title_breadcrumbs: 1]

  def bold_if_active(conn, path, text) do
    requested_path = Enum.at(String.split(conn.request_path, "/"), 1)
    if requested_path == String.trim(path, "/") do
      raw "<strong>#{text}</strong>"
    else
      raw text
    end
  end

  defp has_styleguide_subpages?(%{params: %{"section" => "content"}}), do: true
  defp has_styleguide_subpages?(%{params: %{"section" => "components"}}), do: true
  defp has_styleguide_subpages?(_), do: false

  @spec styleguide_main_content_class(map) :: String.t
  def styleguide_main_content_class(%{all_subpages: _}), do: " col-md-10"
  def styleguide_main_content_class(_), do: ""

  def get_page_classes(module, template) do
    module_class = module
    |> Module.split
    |> Enum.slice(1..-1)
    |> Enum.join("-")
    |> String.downcase

    template_class = template |> String.replace(".html", "-template")

    "#{module_class} #{template_class}"
  end

  def nav_link_content(conn), do: [
      {"Getting Around", "Transit Services, Plan Your Trip, Riding...", :map, static_page_path(conn, :getting_around)},
      {"Fares", "Fares By Mode, Reduced Fares, Passes...", :fare_ticket, fare_path(conn, :index)},
      {"Contact Us", "Phone And Online Support, T-Alerts", :phone, customer_support_path(conn, :index)},
      {"More", "About Us, Business Center, Projects...", :t_logo, static_page_path(conn, :about)}
    ]
end
