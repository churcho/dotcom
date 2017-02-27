defmodule Site.ScheduleV2Controller.PreSelect do
  @moduledoc """
  Checks to see if there is only one possible stop for either
  the origin or the destination. Origin or destination will be
  assigned if there is only one available option. Will not
  overwrite an existing origin or destination
  """

  import Plug.Conn, only: [assign: 3]

  def init(_opts), do: []
  def call(conn, _opts) do
    conn
    |> pre_select_stop(:origin)
    |> pre_select_stop(:destination)
  end

  # Assigns an origin or destination if there is only one available option
  defp pre_select_stop(%Plug.Conn{assigns: %{origin: nil}} = conn, :origin) do
    do_pre_select_stop(conn, conn.assigns.excluded_origin_stops, :origin)
  end
  defp pre_select_stop(%Plug.Conn{assigns: %{origin: origin, destination: nil}} = conn, :destination) when not is_nil(origin) do
    do_pre_select_stop(conn, [origin.id | conn.assigns.excluded_destination_stops], :destination)
  end
  defp pre_select_stop(conn, _) do
    conn
  end

  defp do_pre_select_stop(conn, excluded_ids, key) do
    id_map = Map.new(conn.assigns.all_stops, fn(stop) -> {stop.id, stop} end)
    case Map.keys(id_map) -- excluded_ids do
      [stop_id] -> assign(conn, key, id_map[stop_id])
      _ -> conn
    end
  end
end
