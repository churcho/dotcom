defmodule SiteWeb.TransitNearMeViewTest do
  use SiteWeb.ConnCase, async: true
  import Phoenix.HTML, only: [safe_to_string: 1]
  alias SiteWeb.TransitNearMeView, as: View

  @stop_with_routes %{
    distance: 0.52934802,
    routes: [
     orange_line: [%Routes.Route{id: "Orange", key_route?: true, name: "Orange Line", type: 1}],
     commuter_rail: [
       %Routes.Route{id: "CR-Worcester", key_route?: false, name: "Framingham/Worcester Line", type: 2},
       %Routes.Route{id: "CR-Franklin", key_route?: false, name: "Franklin Line", type: 2},
       %Routes.Route{id: "CR-Needham", key_route?: false, name: "Needham Line", type: 2},
       %Routes.Route{id: "CR-Providence", key_route?: false, name: "Providence/Stoughton Line", type: 2}
      ],
      bus: [
        %Routes.Route{id: "10", key_route?: false, name: "10", type: 3},
        %Routes.Route{id: "39", key_route?: true, name: "39", type: 3},
        %Routes.Route{id: "170", key_route?: false, name: "170", type: 3}
      ]
    ],
    stop: %Stops.Stop{
      accessibility: ["accessible", "elevator", "tty_phone", "escalator_up"],
      address: "145 Dartmouth St Boston, MA 02116-5162",
      id: "place-bbsta",
      latitude: 42.34735,
      longitude: -71.075727,
      name: "Back Bay",
      station?: true
    }
  }


  test "get_type_list/1" do
    @stop_with_routes
    |> Map.get(:routes)
    |> Enum.each(&test_get_type_list/1)
  end

  test "result_container_classes/2 assigns the correct class based on the result set size" do
    large_set = Enum.map(0..8, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", large_set) == "different-class large-set"

    six_set = Enum.map(0..6, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", six_set) == "different-class small-set"

    small_set = Enum.map(0..4, fn _ -> @stop_with_routes end)
    assert View.result_container_classes("different-class", small_set) == "different-class small-set"

    assert View.result_container_classes("different-class", []) == "different-class empty"
  end

  defp test_get_type_list({:bus, routes}) do
    assert View.get_type_list(:bus, routes) |> safe_to_string =~ "Bus: "
  end
  defp test_get_type_list({mode_name, routes}) do
    assert View.get_type_list(mode_name, routes) =~ mode_name
                                                    |> Atom.to_string
                                                    |> String.split("_")
                                                    |> Enum.map(&String.capitalize/1)
                                                    |> Enum.join(" ")
  end
end
