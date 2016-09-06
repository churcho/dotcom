defmodule Site.ModeController do
  use Site.Web, :controller

  alias Site.Mode

  def index(conn, _params) do
    conn
    |> put_view(Site.ModeView)
    |> render("index.html",
      datetime: Util.now,
      grouped_routes: Routes.Repo.all |> Routes.Group.group,
      breadcrumbs: ["Schedules & Maps"]
    )
  end

  def subway(conn, params) do
    Mode.SubwayController.index(conn, params)
  end

  def bus(conn, params) do
    Mode.BusController.index(conn, params)
  end

  def boat(conn, params) do
    Mode.BoatController.index(conn, params)
  end

  def commuter_rail(conn, params) do
    Mode.CommuterRailController.index(conn, params)
  end
end
