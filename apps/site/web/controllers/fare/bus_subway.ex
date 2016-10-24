defmodule Site.FareController.BusSubway do
  use Site.FareController.Behaviour
  alias Fares.Fare
  alias Site.FareController.Filter

  def mode_name(), do: "Bus/Subway"

  def template(), do: "bus_subway.html"

  def fares(_conn) do
    [:subway, :bus]
    |> Enum.flat_map(&Fares.Repo.all(mode: &1))
  end

  def filters(fares) do
    {single_rides, passes} = fares |> Enum.partition(&single_ride?/1)

    [
      %Filter{
        id: "single",
        name: "Single Ride",
        fares: single_rides
      },
      %Filter{
        id: "passes",
        name: "Passes",
        fares: passes
      }
    ]
  end

  defp single_ride?(%Fare{duration: duration}) when duration in [:single_trip, :round_trip] do
    true
  end
  defp single_ride?(%Fare{}) do
    false
  end
end
