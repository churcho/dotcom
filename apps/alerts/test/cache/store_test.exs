defmodule Alerts.Cache.StoreTest do
  use ExUnit.Case

  alias Alerts.Cache.Store

  @now Timex.parse!("2017-06-08T10:00:00-05:00", "{ISO:Extended}")

  test "updating and fetching without a banner" do
    alert1 = %Alerts.Alert{id: "123", informed_entity: [
      %Alerts.InformedEntity{route: "Blue"},
      %Alerts.InformedEntity{stop: "place-pktrm"},
    ]}
    alert2 = %Alerts.Alert{id: "456", informed_entity: [
      %Alerts.InformedEntity{route: "Red"},
    ]}
    alerts = [alert1, alert2]

    Store.update(alerts, nil)

    assert Enum.sort(Store.all_alerts(@now)) == Enum.sort(alerts)
    assert Store.alert_ids_for_routes(["Blue"]) == ["123"]
    assert Store.alert_ids_for_routes([nil]) == ["123"]
    assert Enum.sort(Store.alert_ids_for_routes(["Blue", "Red", "Magenta"])) == ["123", "456"]
    assert Store.alerts(["123"], @now) == [alert1]
    assert Enum.sort(Store.alerts(["123", "456", "xyz"], @now)) == Enum.sort([alert1, alert2])
  end

  test "update and fetches banner" do
    banner = %Alerts.Banner{id: "5", title: "Title", url: "https://google.com"}
    Store.update([], banner)
    assert Store.banner() == banner

    Store.update([], nil)
    assert Store.banner() == nil
  end

  test "alerts come back in sorted order" do
    alert1 = %Alerts.Alert{id: "123", effect_name: "Cancellation"}
    alert2 = %Alerts.Alert{id: "456", effect_name: "Policy Change"}

    Store.update([alert1, alert2], nil)
    assert Store.all_alerts(@now) == [alert1, alert2]
    assert Store.alerts(["123", "456"], @now) == [alert1, alert2]

    Store.update([alert2, alert1], nil)
    assert Store.all_alerts(@now) == [alert1, alert2]
    assert Store.alerts(["123", "456"], @now) == [alert1, alert2]
  end
end
