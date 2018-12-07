defmodule SiteWeb.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import SiteWeb.FareView
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1, html_escape: 1]
  import Phoenix.ConnTest, only: [build_conn: 0]
  alias Fares.{Fare, Summary}

  describe "fare_type_note/2" do
    test "returns fare note for students" do
      note = fare_type_note(build_conn(), %Fare{mode: :commuter_rail, reduced: :student})

      assert note |> List.first() |> safe_to_string() =~
               "Middle and high school students with an MBTA-issued"
    end

    test "returns fare note for seniors" do
      assert safe_to_string(
               fare_type_note(build_conn(), %Fare{mode: :commuter_rail, reduced: :senior_disabled})
             ) =~
               "Seniors are eligible for reduced fares on the subway, bus, Commuter Rail, and ferry"
    end

    test "returns fare note for bus and subway" do
      assert safe_to_string(fare_type_note(build_conn(), %Fare{mode: :bus, reduced: nil})) =~
               "click on the &quot;Passes&quot; tab below"
    end

    test "returns fare note for ferry" do
      assert safe_to_string(fare_type_note(build_conn(), %Fare{mode: :ferry, reduced: nil})) =~
               "You can buy a ferry ticket after you board the boat"
    end

    test "returns fare note for commuter rail" do
      assert safe_to_string(
               fare_type_note(build_conn(), %Fare{mode: :commuter_rail, reduced: nil})
             ) =~ "If you buy a round trip ticket"
    end
  end

  describe "summary_url/1" do
    test "links to :mode-fares for bus/subway summaries" do
      expected = SiteWeb.Router.Helpers.fare_path(SiteWeb.Endpoint, :show, "bus-fares")
      assert summary_url(%Summary{modes: [:bus]}) == expected
      expected = SiteWeb.Router.Helpers.fare_path(SiteWeb.Endpoint, :show, "subway-fares")
      assert summary_url(%Summary{modes: [:subway]}) == expected
    end

    test "if the summary has a duration, link to the correct anchor" do
      expected = SiteWeb.Router.Helpers.fare_path(SiteWeb.Endpoint, :show, "subway-fares")

      assert summary_url(%Summary{modes: [:subway, :bus], duration: :week}) ==
               expected <> "#7-day"

      assert summary_url(%Summary{modes: [:subway, :bus], duration: :month}) ==
               expected <> "#monthly"
    end

    test "links directly for commuter rail/ferry" do
      for mode <- [:commuter_rail, :ferry] do
        expected =
          SiteWeb.Router.Helpers.fare_path(
            SiteWeb.Endpoint,
            :show,
            SiteWeb.StaticPage.convert_path(mode)
          )

        assert summary_url(%Summary{modes: [mode, :bus]}) == expected <> "-fares"
      end
    end

    test "defers to the summary's provided URL if present" do
      assert summary_url(%Summary{modes: [:bus], url: "/expected_url"}) == "/expected_url"
    end
  end

  describe "vending_machine_stations/0" do
    test "generates a list of links to stations with fare vending machines" do
      content =
        vending_machine_stations()
        |> Enum.map(&raw/1)
        |> Enum.map(&safe_to_string/1)
        |> Enum.join("")

      assert content =~ "place-north"
      assert content =~ "place-sstat"
      assert content =~ "place-bbsta"
      assert content =~ "place-brntn"
      assert content =~ "place-forhl"
      assert content =~ "place-jfk"
      assert content =~ "Lynn"
      assert content =~ "place-mlmnl"
      assert content =~ "place-portr"
      assert content =~ "place-qnctr"
      assert content =~ "place-rugg"
      assert content =~ "Worcester"
    end
  end

  describe "charlie_card_stations/0" do
    test "generates a list of links to stations where a customer can buy a CharlieCard" do
      content =
        charlie_card_stations()
        |> Enum.map(&raw/1)
        |> Enum.map(&safe_to_string/1)
        |> Enum.join("")

      assert content =~ "place-alfcl"
      assert content =~ "place-armnl"
      assert content =~ "place-asmnl"
      assert content =~ "place-bbsta"
      assert content =~ "64000"
      assert content =~ "place-forhl"
      assert content =~ "place-harsq"
      assert content =~ "place-north"
      assert content =~ "place-ogmnl"
      assert content =~ "place-pktrm"
      assert content =~ "place-rugg"
    end
  end

  describe "destination_key_stops/2" do
    test "Unavailable key stops are filtered out" do
      key_stop1 = %Stops.Stop{id: 1}
      key_stop2 = %Stops.Stop{id: 2}
      dest_stop1 = %Stops.Stop{id: 4}
      dest_stop2 = %Stops.Stop{id: 5}
      dest_stop3 = %Stops.Stop{id: 2}

      filtered =
        destination_key_stops([dest_stop1, dest_stop2, dest_stop3], [key_stop1, key_stop2])

      assert Enum.count(filtered) == 1
      assert List.first(filtered).id == 2
    end
  end

  describe "format_name/2" do
    test "uses ferry origin and destination" do
      origin = %Stops.Stop{name: "North"}
      dest = %Stops.Stop{name: "South"}

      tag =
        format_name(%Fare{mode: :ferry, duration: :week}, %{origin: origin, destination: dest})

      assert safe_to_string(tag) =~ "North"
      assert safe_to_string(tag) =~ "South"
    end

    test "Non ferry mode uses full name" do
      fare = %Fare{mode: :bus, duration: :week, name: "local_bus"}
      assert format_name(fare, %{}) == Fares.Format.full_name(fare)
    end
  end

  describe "origin_destination_description/2" do
    test "links to the zone fares page for CR" do
      content =
        :commuter_rail |> origin_destination_description() |> html_escape() |> safe_to_string()

      assert content =~ "Select your origin and destination"
      assert content =~ "your Commuter Rail fare"
    end

    test "for ferry" do
      content = :ferry |> origin_destination_description() |> html_escape() |> safe_to_string()
      assert content =~ "Select your origin and destination"
      assert content =~ "ferry fare"
    end
  end

  describe "charlie_card_store_link/1" do
    test "it renders the link properly" do
      rendered =
        SiteWeb.Endpoint
        |> charlie_card_store_link
        |> safe_to_string

      assert rendered ==
               ~s(<span class="no-wrap">\(<a data-turbolinks="false" href="/fares/charlie_card/#store">view details</a>\)</span>)
    end
  end
end
