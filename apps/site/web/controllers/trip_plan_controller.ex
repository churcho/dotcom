defmodule Site.TripPlanController do
  use Site.Web, :controller
  alias Site.TripPlan.{Query, RelatedLink, ItineraryRowList}
  alias Site.TripPlan.Map, as: TripPlanMap
  alias Site.TripPlan.Alerts, as: TripPlanAlerts
  alias TripPlan.Itinerary

  plug :require_google_maps
  plug :assign_initial_map

  @type route_map :: %{optional(Routes.Route.id_t) => Routes.Route.t}
  @type route_mapper :: ((Routes.Route.id_t) -> Routes.Route.t | nil)

  def index(conn, %{"plan" => %{"date_time" => date_time} = plan}) do
    case validate_date(date_time) do
      {:ok, date} ->
        conn
        |> assign(:errors, [])
        |> render_plan(%{plan | "date_time" => future_date_or_now(date, conn.assigns.date_time)})
      {_, errors} ->
        conn
        |> assign(:errors, errors)
        |> render(:index)
    end
  end
  def index(conn, _params) do
    conn
    |> assign(:errors, [])
    |> render(:index)
  end

  defp render_plan(conn, plan) do
    query = Query.from_query(plan)
    itineraries = Query.get_itineraries(query)
    route_map = routes_for_query(itineraries)
    route_mapper = &Map.get(route_map, &1)
    render conn,
      query: query,
      routes: Enum.map(itineraries, &routes_for_itinerary(&1, route_mapper)),
      itinerary_maps: Enum.map(itineraries, &TripPlanMap.itinerary_map(&1, route_mapper: route_mapper)),
      related_links: Enum.map(itineraries, &RelatedLink.links_for_itinerary(&1, route_by_id: route_mapper)),
      alerts: alerts(itineraries, route_mapper),
      itinerary_row_lists: itinerary_row_lists(itineraries, route_mapper, plan)
  end

  @spec validate_date(map) :: {:ok, NaiveDateTime.t} | {:error, %{required(:date_time) => String.t}}
  defp validate_date(%{"year" => year, "month" => month, "day" => day, "hour" => hour, "minute" => minute, "am_pm" => am_pm}) do
    case convert_to_date("#{year}-#{month}-#{day} #{hour}:#{minute} #{am_pm}") do
      nil -> {:error, %{date_time: "Date is not valid."}}
      date -> {:ok, date}
    end
  end
  defp validate_date(%{"year" => year, "month" => month, "day" => day, "hour" => hour, "minute" => minute}) do
    case convert_to_date("#{year}-#{month}-#{day} #{hour}:#{minute}") do
      nil -> {:error, %{date_time: "Date is not valid."}}
      date -> {:ok, date}
    end
  end
  defp validate_date(_) do
    {:error, %{date_time: "Date is not valid."}}
  end

  @spec convert_to_date(String.t) :: NaiveDateTime.t | nil
  defp convert_to_date(date_string) do
    {result, date_time} = Timex.parse(date_string, "{YYYY}-{M}-{D} {_h24}:{_m} {AM}")
    case {result, Timex.is_valid?(date_time)} do
      {:ok, true} -> date_time
      {_, _} -> nil
    end
  end

  @spec future_date_or_now(NaiveDateTime.t, DateTime.t) :: DateTime.t
  defp future_date_or_now(naive_date, system_date_time) do
    local_date_time = Timex.to_datetime(naive_date, system_date_time.time_zone)
    if Timex.after?(local_date_time, system_date_time) do
      local_date_time
    else
      system_date_time
    end
  end

  def require_google_maps(conn, _) do
    assign(conn, :requires_google_maps?, true)
  end

  @spec itinerary_row_lists([Itinerary.t], route_mapper, map) :: [ItineraryRowList.t]
  defp itinerary_row_lists(itineraries, route_mapper, plan) do
    opts = Keyword.merge([route_mapper: route_mapper], to_and_from(plan))
    Enum.map(itineraries, &ItineraryRowList.from_itinerary(&1, opts))
  end

  def assign_initial_map(conn, _opts) do
    conn
    |> assign(:initial_map_src, TripPlanMap.initial_map_src())
    |> assign(:initial_map_data, TripPlanMap.initial_map_data())
  end

  @spec routes_for_query([Itinerary.t]) :: route_map
  defp routes_for_query(itineraries) do
    itineraries
    |> Enum.flat_map(&Itinerary.route_ids/1)
    |> add_additional_routes()
    |> Enum.uniq
    |> Map.new(&{&1, Routes.Repo.get(&1)})
  end

  @spec routes_for_itinerary(Itinerary.t, route_mapper) :: [Routes.Route.t]
  defp routes_for_itinerary(itinerary, route_mapper) do
    itinerary
    |> Itinerary.route_ids
    |> Enum.map(route_mapper)
  end

  @spec alerts([Itinerary.t], route_mapper) :: [alert_list] when alert_list: [Alerts.Alert.t]
  defp alerts([], _) do
    []
  end
  defp alerts([first | _] = itineraries, route_mapper) do
    # time here is only used for sorting, so it's okay that the time might
    # not exactly match the alerts
    all_alerts = Alerts.Repo.all(first.start)
    opts = [route_by_id: route_mapper]
    for itinerary <- itineraries do
      TripPlanAlerts.filter_for_itinerary(all_alerts, itinerary, opts)
    end
  end

  @spec to_and_from(map) :: [to: String.t | nil, from: String.t | nil]
  def to_and_from(plan) do
    [to: Map.get(plan, "to"), from: Map.get(plan, "from")]
  end

  defp add_additional_routes(ids) do
    if Enum.any?(ids, &String.starts_with?(&1, "Green")) do
      Enum.concat(ids, GreenLine.branch_ids()) # no cover
    else
      ids
    end
  end
end
