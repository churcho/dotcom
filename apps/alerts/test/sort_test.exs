defmodule Alerts.SortTest do
  use ExUnit.Case, async: true
  use Quixir

  alias Alerts.Alert
  import Alerts.Sort

  describe "sort/2" do
    test "sorts the notices by their updated at times (newest to oldest)" do
      date = Timex.today() |> Timex.shift(days: 1) # put them in the future
      ptest times: list(positive_int()) do
        # create alerts with a bunch of updated_at times
        alerts = for time <- times do
          dt = date |> Timex.shift(seconds: time)
          %Alert{id: inspect(make_ref()),
                 updated_at: dt,
                 active_period: [{nil, nil}]}
        end

        actual = sort(alerts, DateTime.utc_now())
        # reverse after ID sort so that the second reverse puts them in the
        # right order
        expected = alerts
        |> Enum.sort_by(&(&1.id))
        |> Enum.reverse()
        |> Enum.sort_by(&(&1.updated_at), &Timex.after?/2)

        assert actual == expected
      end
    end

    test "uses the passed in date for active periods" do
      alert_prototype = %Alert{
        effect: :snow_route,
        lifecycle: "Upcoming",
        severity: 7,
        updated_at: new_datetime("2017-06-01T12:00:00-05:00")
      }
      period_1 = {new_datetime("2017-06-10T08:00:00-05:00"), new_datetime("2017-06-12T22:00:00-05:00")}
      period_2 = {new_datetime("2017-06-04T08:00:00-05:00"), new_datetime("2017-06-06T22:00:00-05:00")}
      alert_1 =
        alert_prototype
        |> Map.put(:active_period, [period_1])
        |> Map.put(:id, 1)
      alert_2 =
        alert_prototype
        |> Map.put(:active_period, [period_2])
        |> Map.put(:id, 2)

      sorted_alerts = sort([alert_1, alert_2], new_datetime("2017-06-01T12:00:00-05:00"))
      assert sorted_alerts == [alert_2, alert_1]

      re_sorted_alerts = sort([alert_1, alert_2], new_datetime("2017-06-08T12:00:00-05:00"))
      assert re_sorted_alerts == [alert_1, alert_2]
    end

    test "prioritizes alerts over notices" do
      {:ok, now, _} = DateTime.from_iso8601("2018-04-03T11:00:00Z")
      period_1 = {Timex.shift(now, hours: -1), Timex.shift(now, hours: 1)}
      alert_prototype = %Alert{
        effect: :snow_route,
        lifecycle: "New",
        severity: 5,
        updated_at: Timex.shift(now, hours: -3),
        active_period: [period_1]
      }

      notice_1 = %{alert_prototype | severity: 3, effect: :access_issue, id: 1}
      notice_2 = %{alert_prototype | severity: 3, effect: :access_issue, id: 2}
      alert_1 = %{alert_prototype | severity: 5, effect: :snow_route, id: 3}
      alerts = [notice_1, alert_1, notice_2]

      assert Alerts.Alert.is_notice?(notice_1, now)
      assert Alerts.Alert.is_notice?(notice_2, now)
      refute Alerts.Alert.is_notice?(alert_1, now)

      sorted_effects = alerts
                      |> Alerts.Sort.sort(now)
                      |> Enum.map(&(&1.effect))
      assert sorted_effects == [:snow_route, :access_issue, :access_issue]

    end

    def new_datetime(str) do
      Timex.parse!(str, "{ISO:Extended}")
    end
  end
end
