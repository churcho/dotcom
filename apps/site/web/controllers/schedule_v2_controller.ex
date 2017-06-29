defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller
  alias Routes.Route

  plug Site.Plugs.Route

  @spec show(Plug.Conn.t, map) :: Phoenix.HTML.Safe.t
  def show(%{query_params: %{"tab" => "timetable"} = query_params} = conn, _params) do
    tab_redirect(conn, timetable_path(conn, :show, conn.assigns.route.id, Map.delete(query_params, "tab")))
  end
  def show(%{query_params: %{"tab" => "trip-view"} = query_params} = conn, _params) do
    tab_redirect(conn, trip_view_path(conn, :show, conn.assigns.route.id, Map.delete(query_params, "tab")))
  end
  def show(%{query_params: %{"tab" => "line"} = query_params} = conn, _params) do
    tab_redirect(conn, line_path(conn, :show, conn.assigns.route.id, Map.delete(query_params, "tab")))
  end
  def show(%{assigns: %{route: %Route{type: 2, id: route_id}}, query_params: query_params} = conn, _params) do
    tab_redirect(conn, timetable_path(conn, :show, route_id, query_params))
  end
  def show(%{assigns: %{route: %Route{id: route_id}}, query_params: query_params} = conn, _params) do
    tab_redirect(conn, line_path(conn, :show, route_id, query_params))
  end

  defp tab_redirect(conn, path) do
    conn
    |> redirect(to: path)
    |> halt()
  end
end
