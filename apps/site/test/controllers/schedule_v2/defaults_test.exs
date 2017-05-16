defmodule Site.ScheduleV2Controller.DefaultsTest do
  use Site.ConnCase, async: true
  alias Site.ScheduleV2Controller.Defaults
  alias Routes.Route

  setup %{conn: conn} do
    conn =
      conn
      |> assign(:route, %Route{id: "1", type: 3})
      |> assign(:date_time, Util.now())
      |> assign(:date, Util.service_date())
      |> fetch_query_params()
    {:ok, conn: conn}
  end

  describe "assigns headsigns to" do
    test "correct headsigns if route has been assigned", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.headsigns == %{0 => ["Harvard"], 1 => ["Dudley"]}
    end
  end

  describe "assigns show_date_select? to" do
    test "false when not in params", %{conn: conn} do
      conn = Defaults.call(conn, [])
      assert conn.assigns.show_date_select? == false
    end

    test "true when true in params", %{conn: conn} do
      conn = %{conn | params: %{"date_select" => "true"}}
      conn = Defaults.call(conn, [])
      assert conn.assigns.show_date_select? == true
    end
  end

  describe "assign direction_id to" do
    test "integer when in params", %{conn: conn} do
      conn = Defaults.call(%{conn | query_params: %{"direction_id" => "1"}}, [])
      assert conn.assigns.direction_id == 1
    end

    test "0 when id is not in params and after 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:date_time, ~N[2017-01-25T14:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 0
    end

    test "1 when id is not in params and before 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:date_time, ~N[2017-01-25T13:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 1
    end

    test "silverline is 1 when id is not in params and after 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:route, %Route{id: "741", type: 3})
      |> assign(:date_time, ~N[2017-01-25T14:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 1
    end

    test "silverline is 0 when id is not in params and before 1:59pm", %{conn: conn} do
      conn = conn
      |> assign(:route, %Route{id: "741", type: 3})
      |> assign(:date_time, ~N[2017-01-25T13:00:00])
      |> Defaults.call([])
      assert conn.assigns.direction_id == 0
    end
  end
end
