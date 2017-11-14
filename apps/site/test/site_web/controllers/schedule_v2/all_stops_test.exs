defmodule SiteWeb.ScheduleV2Controller.AllStopsTest do
  use SiteWeb.ConnCase, async: true
  alias SiteWeb.ScheduleV2Controller.AllStops

  @moduletag :external

  test "deduplicates red line stops", %{conn: conn} do
    conn = conn
    |> assign(:date, nil)
    |> assign(:direction_id, 1)
    |> assign(:route, %Routes.Route{id: "Red"})
    |> AllStops.call([])

    all_stops = conn.assigns[:all_stops]

    assert length(all_stops) == length(Enum.uniq_by(all_stops, &(&1.id)))
  end
end
