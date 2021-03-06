defmodule SiteWeb.ScheduleController.TimetableController do
  @moduledoc "Handles the Timetable tab for commuter rail routes."
  use SiteWeb, :controller
  alias Plug.Conn
  alias Routes.Route
  alias SiteWeb.ScheduleView

  plug(SiteWeb.Plugs.Route)
  plug(SiteWeb.Plugs.DateInRating)
  plug(:tab_name)
  plug(:direction_id)
  plug(:all_stops)
  plug(SiteWeb.ScheduleController.RoutePdfs)
  plug(SiteWeb.ScheduleController.Core)
  plug(:do_assign_trip_schedules)
  plug(SiteWeb.ScheduleController.Offset)
  plug(SiteWeb.ScheduleController.ScheduleError)
  plug(:channel_id)

  defdelegate direction_id(conn, params),
    to: SiteWeb.ScheduleController.Defaults,
    as: :assign_direction_id

  def show(conn, _) do
    direction_id = conn.assigns[:direction_id]
    direction_name = conn.assigns.route.direction_names[direction_id]

    {:ok, formatted_date} = Timex.format(conn.assigns.date, "{Mfull} {D}, {YYYY}")

    conn
    |> assign(
      :meta_description,
      "MBTA #{conn.assigns.route.name} Commuter Rail stations and " <>
        "schedules, including timetables, maps, fares, real-time updates, parking and accessibility information, " <>
        "and connections."
    )
    |> assign(:direction_name, direction_name)
    |> assign(:formatted_date, formatted_date)
    |> put_view(ScheduleView)
    |> render("show.html", [])
  end

  # Plug that assigns trip schedule to the connection
  defp do_assign_trip_schedules(conn, _) do
    Util.log_duration(__MODULE__, :assign_trip_schedules, [conn])
  end

  def assign_trip_schedules(conn) do
    timetable_schedules = timetable_schedules(conn)
    header_schedules = header_schedules(timetable_schedules)
    vehicle_schedules = vehicle_schedules(conn, timetable_schedules)
    prior_stops = prior_stops(vehicle_schedules)

    %{
      trip_schedules: trip_schedules,
      all_stops: all_stops
    } = build_timetable(conn.assigns.all_stops, timetable_schedules)

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:header_schedules, header_schedules)
    |> assign(:trip_schedules, trip_schedules)
    |> assign(:vehicle_schedules, vehicle_schedules)
    |> assign(:prior_stops, prior_stops)
    |> assign(:trip_messages, trip_messages(conn.assigns.route, conn.assigns.direction_id))
    |> assign(:all_stops, all_stops)
  end

  # Helper function for obtaining schedule data
  @spec timetable_schedules(Plug.Conn.t()) :: [Schedules.Schedule.t()]
  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    case Schedules.Repo.by_route_ids([route.id], date: date, direction_id: direction_id) do
      {:error, _} -> []
      schedules -> schedules
    end
  end

  @spec trip_messages(Routes.Route.t(), 0 | 1) :: %{{String.t(), String.t()} => String.t()}
  def trip_messages(%Routes.Route{id: "CR-Haverhill"}, 0) do
    %{
      {"221"} => "Via Lowell Line",
      {"221", "place-WR-0067"} => "Via",
      {"221", "place-WR-0075"} => "Lowell",
      {"221", "place-WR-0085"} => "Line"
    }
  end

  def trip_messages(%Routes.Route{id: "CR-Haverhill"}, 1) do
    %{
      {"208"} => "Via Lowell Line",
      {"208", "place-WR-0085"} => "Via",
      {"208", "place-WR-0075"} => "Lowell",
      {"208", "place-WR-0067"} => "Line"
    }
  end

  def trip_messages(%Routes.Route{id: "CR-Lowell"}, 0) do
    %{
      {"221"} => "Via Haverhill",
      {"221", "place-NHRML-0218"} => "Via",
      {"221", "place-NHRML-0254"} => "Haverhill"
    }
  end

  def trip_messages(%Routes.Route{id: "CR-Lowell"}, 1) do
    %{
      {"208"} => "Via Haverhill",
      {"208", "place-NHRML-0254"} => "Via",
      {"208", "place-NHRML-0218"} => "Haverhill",
      {"208", "place-NHRML-0152"} => "-"
    }
  end

  def trip_messages(%Routes.Route{id: "CR-Franklin"}, 1) do
    ["740", "746", "748", "750", "754", "726", "758"]
    |> Enum.flat_map(&franklin_via_fairmount(&1, 1))
    |> Enum.into(%{})
  end

  def trip_messages(%Routes.Route{id: "CR-Franklin"}, 0) do
    ["741", "743", "747", "749", "755", "757", "759"]
    |> Enum.flat_map(&franklin_via_fairmount(&1, 0))
    |> Enum.into(%{})
  end

  def trip_messages(%Routes.Route{id: "CR-Fairmount"} = route, 1) do
    %{
      {"726"} => ScheduleView.timetable_note(%{route: route, direction_id: 1}),
      {"726", "place-FS-0049"} => "FRANK"
    }
  end

  def trip_messages(_, _) do
    %{}
  end

  defp franklin_via_fairmount(train, 1) do
    [
      List.duplicate(train, 3),
      stops_for_fairmount(1),
      ["Via", "Fairmount", "Line"]
    ]
    |> make_via_list()
    |> Enum.concat([{{train}, "Via Fairmount Line"}])
  end

  defp franklin_via_fairmount(train, 0) do
    [
      List.duplicate(train, 4),
      stops_for_fairmount(0),
      ["Via", "Fair-", "mount", "Line"]
    ]
    |> make_via_list()
    |> Enum.concat([{{train}, "Via Fairmount Line"}])
  end

  defp stops_for_fairmount(1) do
    ["place-DB-0095", "place-rugg", "place-bbsta"]
  end

  defp stops_for_fairmount(0) do
    ["place-bbsta", "place-rugg", "place-NEC-2203", "place-DB-0095"]
  end

  def make_via_list(list) do
    list
    |> List.zip()
    |> Enum.map(fn {train, stop, value} -> {{train, stop}, value} end)
  end

  defp all_stops(conn, _) do
    # we override the default fetch of all_stops to not use the date. We will
    # use the date to fetch the actual schedule data.
    all_stops =
      Stops.Repo.by_route(conn.assigns.route.id, conn.assigns.direction_id,
        date: conn.assigns.date
      )

    assign(conn, :all_stops, all_stops)
  end

  defp tab_name(conn, _), do: assign(conn, :tab, "timetable")

  @spec build_timetable([Stops.Stop.t()], [Schedules.Schedule.t()]) :: %{
          required(:trip_schedules) => %{
            required({Schedules.Trip.id_t(), Stops.Stop.id_t()}) => Schedules.Schedule.t()
          },
          required(:all_stops) => [Stops.Stop.t()]
        }
  def build_timetable(all_stops, schedules) do
    trip_schedules = Map.new(schedules, &{{&1.trip.id, &1.stop.id}, &1})
    all_stops = remove_unused_stops(all_stops, schedules)

    %{
      trip_schedules: trip_schedules,
      all_stops: all_stops
    }
  end

  @spec header_schedules(list) :: list
  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times()
    |> Enum.map(&List.first/1)
  end

  @spec vehicle_schedules(Conn.t(), list) :: map
  def vehicle_schedules(%{assigns: %{date: date}}, timetable_schedules) do
    case Date.compare(date, Util.service_date()) do
      :eq -> do_vehicle_schedules(timetable_schedules)
      _ -> %{}
    end
  end

  def do_vehicle_schedules(timetable_schedules) do
    timetable_schedules
    |> Enum.map(&construct_vehicle_data/1)
    |> Map.new(&{"#{&1.stop_name}-#{&1.trip_id}", &1})
  end

  defp construct_vehicle_data(%Schedules.Schedule{
         stop: nil,
         stop_sequence: s,
         trip: %Schedules.Trip{id: ti, headsign: headsign}
       }) do
    %{stop_sequence: s, stop_name: headsign, trip_id: ti}
  end

  defp construct_vehicle_data(%Schedules.Schedule{
         stop: %Stops.Stop{name: sn},
         stop_sequence: s,
         trip: %Schedules.Trip{id: ti}
       }) do
    %{stop_sequence: s, stop_name: sn, trip_id: ti}
  end

  defp construct_vehicle_data(%Schedules.Schedule{
         route: %Route{description: :rail_replacement_bus},
         stop_sequence: s,
         trip: %Schedules.Trip{id: ti, headsign: headsign}
       }) do
    %{stop_sequence: s, stop_name: headsign, trip_id: ti}
  end

  @spec prior_stops(map) :: map
  def prior_stops(vehicle_schedules) do
    vehicle_schedules
    |> Map.values()
    |> Map.new(&{"#{&1.trip_id}-#{&1.stop_sequence}", "#{&1.stop_name}-#{&1.trip_id}"})
  end

  defp remove_unused_stops(all_stops, schedules) do
    timetable_stop = MapSet.new(schedules, & &1.stop.id)
    Enum.filter(all_stops, &MapSet.member?(timetable_stop, &1.id))
  end

  defp channel_id(conn, _) do
    assign(conn, :channel, "vehicles:#{conn.assigns.route.id}:#{conn.assigns.direction_id}")
  end
end
