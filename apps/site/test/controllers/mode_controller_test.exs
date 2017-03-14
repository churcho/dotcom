defmodule Site.ModeControllerTest do
  use Site.ConnCase, async: true

  for mode <- ~W(index subway bus ferry commuter_rail)a do
    test_name = "renders the #{mode} mode page"
    test test_name, %{conn: conn} do
      assert conn
      |> get(mode_path(conn, unquote(mode)))
      |> html_response(200)
    end
  end

  test "test mode redirect route_id", %{conn: conn} do
    assert conn
    |> get(mode_path(conn, :index, route: "CR-Fitchburg"))
    |> redirected_to() == "/schedules/CR-Fitchburg"
  end
end
