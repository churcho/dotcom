defmodule Algolia.MockRoutesRepo do
  def by_stop("place-subway") do
    [get("HeavyRail")]
  end

  def by_stop("place-multi") do
    Enum.map(["HeavyRail", "LightRail", "1000", "CR-Commuterrail"], &get/1)
  end
  def by_stop("place-greenline") do
    [get("LightRail")]
  end
  def by_stop("place-commuter-rail") do
    [get("CR-Commuterrail")]
  end
  def by_stop("place-ferry") do
    [get("Boat-1000")]
  end

  def green_line do
    Routes.Repo.green_line()
  end

  def all do
    Enum.map(["HeavyRail", "LightRail", "CR-Commuterrail", "1000", "Boat-1000"], &get/1)
  end

  def get("HeavyRail"), do: %Routes.Route{id: "HeavyRail", key_route?: true, name: "Heavy Rail", type: 1}
  def get("LightRail"), do: %Routes.Route{id: "Green-LightRail", key_route?: true, name: "Light Rail", type: 0}

  def get("CR-Commuterrail"), do: %Routes.Route{id: "CR-Commuterrail", name: "Commuter Rail Line", type: 2}
  def get("1000"), do: %Routes.Route{id: "1000", name: "1000", type: 3}
  def get("Boat-1000"), do: %Routes.Route{id: "Boat-1000", key_route?: false, name: "Ferry Route", type: 4}
end
