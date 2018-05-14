defmodule SiteWeb.AlertView do
  use SiteWeb, :view
  alias Routes.Route
  alias SiteWeb.PartialView.SvgIconWithCircle
  import SiteWeb.ViewHelpers

  @doc """

  Used by the schedule view to render a link/modal with relevant alerts.

  """
  def modal(opts) do
    alerts = Keyword.fetch!(opts, :alerts)
    _ = Keyword.fetch!(opts, :route)

    upcoming_alerts = opts[:upcoming_alerts] || []

    opts = opts
    |> Keyword.put(:upcoming_alert_count, length(upcoming_alerts))

    case {alerts, upcoming_alerts} do
      {[], []} -> ""
      _ ->
        render(__MODULE__, "modal.html", opts)
    end
  end

  @doc """

  Renders an inline list of alerts, passed in as the alerts key.

  """
  def inline(_conn, [{:alerts, []}|_]) do
    ""
  end
  def inline(_conn, [{:alerts, nil}|_]) do
    ""
  end
  def inline(_conn, assigns) do
    case Keyword.get(assigns, :time) do
      value when not is_nil(value) ->
        render(__MODULE__, "inline.html", assigns)
    end
  end

  @doc """
  """
  def alert_effects(alerts, upcoming_count)
  def alert_effects([], 0), do: "There are no alerts for today."
  def alert_effects([], 1), do: "There are no alerts for today; 1 upcoming alert."
  def alert_effects([], count), do: ["There are no alerts for today; ", count |> Integer.to_string, " upcoming alerts."]
  def alert_effects([alert], _) do
    {Alerts.Alert.human_effect(alert),
     ""}
  end
  def alert_effects([alert|rest], _) do
    {Alerts.Alert.human_effect(alert),
     ["+", rest |> length |> Integer.to_string, " more"]}
  end

  def effect_name(%{lifecycle: lifecycle} = alert)
  when lifecycle in [:new, :unknown] do
    Alerts.Alert.human_effect(alert)
  end
  def effect_name(alert) do
    [Alerts.Alert.human_effect(alert),
     " (",
     Alerts.Alert.human_lifecycle(alert),
     ")"]
  end

  def alert_updated(alert, relative_to) do
    date = if Timex.equal?(relative_to, alert.updated_at) do
      "Today at"
    else
      Timex.format!(alert.updated_at, "{M}/{D}/{YYYY}")
    end
    time = format_schedule_time(alert.updated_at)

    ["Last Updated: ", date, 32, time]
  end

  def alert_character_limits do
    [{{:xxs, :sm}, 58},
     {{:xs, :md}, 100},
     {{:sm, :lg}, 160},
     {{:md, :xxl}, 220},
     {{:lg, :xxxl}, 260}
    ]
  end

  def clamp_header(header, effects, max_chars) do
    trunc = truncate_at(effects, max_chars)

    case String.split_at(header, trunc) do
      {short, ""} -> short
      {short, _} -> [String.trim(short), "…"] # ellipsis
    end
  end

  defp truncate_at(effects, max_chars) do
    extra_length = case effects do
      {prefix, suffix} ->
        [prefix, suffix]
        |> Enum.map(&IO.iodata_to_binary/1)
        |> Enum.map(&String.length/1)
        |> Enum.reduce(0, &(&1 + &2))
      text ->
        text
        |> IO.iodata_to_binary
        |> String.length
    end

    max_chars - extra_length
  end

  def format_alert_description(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    |> String.replace(~r/^(.*:)\s/, "<strong>\\1</strong>\n") # an initial header
    |> String.replace(~r/\n(.*:)\s/, "<br /><strong>\\1</strong>\n") # all other start with a line break
    |> String.replace(~r/\s*\n/s, "<br />")
    |> replace_urls_with_links
  end

  @url_regex ~r/(https?:\/\/)?([\da-z\.-]+)\.([a-z]{2,6})([\/\w\.-]*)*\/?/i

  @spec replace_urls_with_links(String.t) :: Phoenix.HTML.safe
  def replace_urls_with_links(text) do
    @url_regex
    |> Regex.replace(text, &create_url/1)
    |> raw
  end

  defp create_url(url) do
    # I could probably convince the Regex to match an internal period but not
    # one at the end, but this is clearer. -ps
    {url, suffix} = if String.ends_with?(url, ".") do
      String.split_at(url, -1)
    else
      {url, ""}
    end
    full_url = ensure_scheme(url)
    ~s(<a target="_blank" href="#{full_url}">#{url}</a>#{suffix})
  end

  defp ensure_scheme("http://" <> _ = url), do: url
  defp ensure_scheme("https://" <> _ = url), do: url
  defp ensure_scheme(url), do: "http://" <> url

  @spec show_mode_icon?(Route.t) :: boolean
  defp show_mode_icon?(%Route{name: name}) when name in ["Escalator", "Elevator", "Other"], do: false
  defp show_mode_icon?(%Route{type: type}) when type in [0, 1], do: true
  defp show_mode_icon?(_), do: false
end
