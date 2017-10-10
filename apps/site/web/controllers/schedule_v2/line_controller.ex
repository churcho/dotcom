defmodule Site.ScheduleV2Controller.LineController do
  use Site.Web, :controller

  plug Site.Plugs.Route
  plug :tab_name
  plug Site.ScheduleV2Controller.Defaults
  plug :all_alerts
  plug Site.Plugs.UpcomingAlerts
  plug Site.ScheduleV2Controller.AllStops
  plug Site.ScheduleV2Controller.RouteBreadcrumbs
  plug Site.ScheduleV2Controller.HoursOfOperation
  plug Site.ScheduleV2Controller.Holidays
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.ScheduleV2Controller.Predictions
  plug Site.ScheduleV2Controller.VehicleTooltips
  plug Site.ScheduleV2Controller.Line
  plug :require_map

  def show(conn, _) do
    render(conn, Site.ScheduleV2View, "show.html", [])
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "line")

  defp all_alerts(conn, _), do: assign_all_alerts(conn, [])

  defp require_map(conn, _), do: assign(conn, :requires_google_maps?, true)
end
