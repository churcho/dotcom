defmodule SiteWeb.AlertViewTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1, raw: 1]
  import SiteWeb.AlertView
  alias Alerts.Alert

  @route %Routes.Route{type: 2, id: "route_id", name: "Name"}

  describe "alert_effects/1" do
    test "returns one alert for one effect" do
      delay_alert = %Alert{effect: :delay, lifecycle: :upcoming}

      expected = {"Delay", ""}
      actual = alert_effects([delay_alert], 0)

      assert expected == actual
    end

    test "returns a count with multiple alerts" do
      alerts = [
        %Alert{effect: :suspension, lifecycle: :new},
        %Alert{effect: :delay},
        %Alert{effect: :cancellation}
      ]

      expected = {"Suspension", ["+", "2", " more"]}
      actual = alert_effects(alerts, 0)

      assert expected == actual
    end

    test "returns text when there are no current alerts" do
     assert [] |> alert_effects(0) |> :erlang.iolist_to_binary == "There are no alerts for today."
     assert [] |> alert_effects(1) |> :erlang.iolist_to_binary == "There are no alerts for today; 1 upcoming alert."
     assert [] |> alert_effects(2) |> :erlang.iolist_to_binary == "There are no alerts for today; 2 upcoming alerts."
    end
  end

  describe "effect_name/1" do
    test "returns the effect name for new alerts" do
      assert "Delay" == effect_name(%Alert{effect: :delay, lifecycle: :new})
    end

    test "includes the lifecycle for alerts" do
      assert "Shuttle (Upcoming)" == %Alert{effect: :shuttle, lifecycle: :upcoming} |> effect_name |> IO.iodata_to_binary
    end
  end

  describe "alert_updated/1" do
    test "returns the relative offset based on our timezone" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-05]
      alert = %Alert{updated_at: now}

      expected = "Last Updated: Today at 12:02A"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary
      assert actual == expected
    end

    test "alerts from further in the past use a date" do
      now = ~N[2016-10-05T00:02:03]
      date = ~D[2016-10-06]

      alert = %Alert{updated_at: now}

      expected = "Last Updated: 10/5/2016 12:02A"
      actual = alert |> alert_updated(date) |> :erlang.iolist_to_binary
      assert actual == expected
    end
  end

  describe "clamp_header/1" do
    test "short headers are the same" do
      assert clamp_header("short", {"", ""}, 58) == "short"
    end

    test "adds an ellipsis to truncated headers" do
      truncated =
        "x"
        |> String.duplicate(65)
        |> clamp_header({"", ""}, 60)
        |> IO.iodata_to_binary

      assert String.ends_with?(truncated, "…")
    end

    test "anything more than the provided character limit gets chomped" do
      long = String.duplicate("x", 65)
      assert long |> clamp_header({"", ""}, 60) |> :erlang.iolist_to_binary |> String.length == 61
    end

    test "clamps that end in a space have it trimmed" do
      text = String.duplicate(" ", 61)
      assert text |> clamp_header({"", ""}, 60) |> :erlang.iolist_to_binary |> String.length == 1
    end

    test "the max length includes prefix and suffix for the alert" do
      long = String.duplicate("x", 61)
      length = long
               |> clamp_header({"prefix", "suffix"}, 60)
               |> IO.iodata_to_binary
               |> String.length

      assert length == 60 - (String.length("prefix") + String.length("suffix")) + 1
    end

    test "the max length includes the effects string if it is not split into prefix/suffix" do
      long = String.duplicate("x", 61)
      length = long
               |> clamp_header("effects string", 60)
               |> IO.iodata_to_binary
               |> String.length

      assert length == 60 - String.length("effects string") + 1
    end
  end

  describe "alert_character_limits" do
    test "has a minimum breakpoint, maximum breakpoint, and character limit" do
      for constraints <- alert_character_limits() do
        assert {{_min, _max}, _chars} = constraints
      end
    end
  end

  describe "format_alert_description/1" do
    test "escapes existing HTML" do
      expected = {:safe, "&lt;br&gt;"}
      actual = format_alert_description("<br>")

      assert expected == actual
    end

    test "replaces newlines with breaks" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\nthere")

      assert expected == actual
    end

    test "combines multiple newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\n\n\nthere")

      assert expected == actual
    end

    test "combines multiple Windows newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\r\n\r\nthere")

      assert expected == actual
    end

    test "<strong>ifies a header" do
      expected = {:safe, "hi<br /><strong>Header:</strong><br />7:30"}
      actual = format_alert_description("hi\nHeader:\n7:30")

      assert expected == actual
    end

    test "<strong>ifies a starting long header" do
      expected = {:safe, "<strong>Long Header:</strong><br />7:30"}
      actual = format_alert_description("Long Header:\n7:30")

      assert expected == actual
    end

    test "linkifies a URL" do
      expected = raw(~s(before <a target="_blank" href="http://mbta.com">http://mbta.com</a> after))
      actual = format_alert_description("before http://mbta.com after")

      assert expected == actual
    end
  end

  describe "replace_urls_with_links/1" do
    test "does not include a period at the end of the URL" do
      expected = raw(~s(<a target="_blank" href="http://mbta.com/foo/bar">http://mbta.com/foo/bar</a>.))
      actual = replace_urls_with_links("http://mbta.com/foo/bar.")

      assert expected == actual
    end

    test "can replace multiple URLs" do
      expected = raw(~s(<a target="_blank" href="http://one.com">http://one.com</a> \
<a target="_blank" href="https://two.net">https://two.net</a>))
      actual = replace_urls_with_links("http://one.com https://two.net")

      assert expected == actual
    end

    test "adds http:// to the URL if it's missing" do
      expected = raw(~s(<a target="_blank" href="http://http.com">http.com</a>))
      actual = replace_urls_with_links("http.com")

      assert expected == actual
    end

    test "does not link short TLDs" do
      expected = raw("a.m.")
      actual = replace_urls_with_links("a.m.")
      assert expected == actual
    end
  end

  describe "modal.html" do
    test "text for no current alerts and 1 upcoming alert" do
      response = SiteWeb.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 1, route: @route, time: Util.now)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end

    test "text for no current alerts and 2 upcoming alerts" do
      response = SiteWeb.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 2, route: @route, time: Util.now)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
    end
  end

  describe "inline/2" do
    test "raises an exception if time is not an option" do
      assert catch_error(
        SiteWeb.AlertView.inline(SiteWeb.Endpoint, [])
      )
    end

    test "renders nothing if no alerts are passed in" do
      result = SiteWeb.AlertView.inline(SiteWeb.Endpoint,
        alerts: [],
        time: Util.service_date)

      assert result == ""
    end

    test "renders if a list of alerts and times is passed in" do
      result = SiteWeb.AlertView.inline(SiteWeb.Endpoint,
        alerts: [%Alert{effect: :delay, lifecycle: :upcoming,
                        updated_at: Util.now}],
        time: Util.service_date)

      refute safe_to_string(result) == ""
    end
  end

  describe "_item.html" do
    @alert %Alert{effect: :access_issue, updated_at: ~D[2017-03-01], header: "Alert Header", description: "description"}
    @time ~N[2017-03-01T07:29:00]

    test "Displays full description button if alert has description" do
      response = SiteWeb.AlertView.render("_item.html", alert: @alert, time: @time)
      assert safe_to_string(response) =~ "View Full Description"
    end

    test "Does not display full description button if description is nil" do
      response = SiteWeb.AlertView.render("_item.html", alert: %{@alert | description: nil}, time: @time)
      refute safe_to_string(response) =~ "View Full Description"
    end
  end
end
