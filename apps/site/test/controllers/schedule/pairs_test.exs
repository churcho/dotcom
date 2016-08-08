defmodule Site.ScheduleController.PairsTest do
  use Site.ConnCase, async: true

  test "origin/destination pairs returns Departure/Arrival times", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "CR-Lowell", origin: "Anderson/ Woburn", dest: "North Station", direction_id: "1")
    response = html_response(conn, 200)
    assert response =~ "Departure"
    assert response =~ "Arrival"
    assert HtmlSanitizeEx.strip_tags(response) =~ ~R(Inbound\s+to: North Station)
  end

  test "links to origin and destination station pages", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-alfcl", dest: "place-harsq", direction_id: "0")
    response = html_response(conn, 200)
    assert response =~ ~s(<option value="place-alfcl" selected>Alewife</option>)
    assert response =~ ~s(<option value="place-harsq" selected>Harvard</option>)
  end

  test "handles an empty schedule", %{conn: conn} do
    conn = get conn, schedule_path(conn, :index, route: "Red", origin: "place-alfcl", dest: "place-harsq", direction_id: "0", date: "2100-01-01")
    response = html_response(conn, 200)
    assert response =~ ~s(There are no currently scheduled trips on January 1, 2100.)
  end
end
