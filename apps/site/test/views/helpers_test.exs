defmodule Site.ViewHelpersTest do
  @moduledoc false
  use Site.ConnCase, async: true

  import Site.ViewHelpers
  import Phoenix.HTML.Tag, only: [tag: 2]
  import Phoenix.HTML, only: [safe_to_string: 1, html_escape: 1]
  alias Routes.Route

  describe "route_header_text/2" do
    test "translates the type number to a string" do
      assert route_header_text(%Route{type: 0, name: "test route"}) == ["test route"]
      assert route_header_text(%Route{type: 3, name: "2"}) == ["Route ", "2"]
      assert route_header_text(%Route{type: 1, name: "Red Line"}) == ["Red Line"]
      assert route_header_text(%Route{type: 2, name: "Fitchburg Line"}) == ["Fitchburg"]
    end
  end

  describe "break_text_at_slash/1" do
    test "doesn't change text without slashes" do
      s = "this text doesn't contain a slash"
      assert s == break_text_at_slash(s)
    end

    test "adds zero width spaces after slashes" do
      s = "abc/123/xyz"
      result = break_text_at_slash(s)
      assert String.length(result) == 13
      assert result == "abc/​123/​xyz"
    end
  end

  describe "hidden_query_params/2" do
    test "creates a hidden tag for each query parameter", %{conn: conn} do
      actual = hidden_query_params(%{conn | query_params: %{"one" => "value", "two" => "other"}})

      expected = [tag(:input, type: "hidden", name: "one", value: "value"),
                  tag(:input, type: "hidden", name: "two", value: "other")]

      assert expected == actual
    end

    test "can handle nested params", %{conn: conn} do
      query_params = %{"location" => %{"address" => "value"}}
      actual = hidden_query_params(%{conn | query_params: query_params})
      expected = [
        tag(:input, type: "hidden", name: "location[address]", value: "value")
      ]

      assert actual == expected
    end

    test "can handle lists of params", %{conn: conn} do
      query_params = %{"address" => ["one", "two"]}
      actual = hidden_query_params(%{conn | query_params: query_params})
      expected = [
        tag(:input, type: "hidden", name: "address[]", value: "one"),
        tag(:input, type: "hidden", name: "address[]", value: "two")
      ]

      assert actual == expected
    end
  end

  describe "stop_link/1" do
    test "given a stop, returns a link to that stop" do
      link = %Stops.Stop{id: "place-sstat", name: "South Station"}
      |> stop_link
      |> safe_to_string
      assert link == ~s(<a href="/stops/place-sstat">South Station</a>)
    end

    test "given a stop ID, returns a link to that stop" do
      link = "place-sstat"
      |> stop_link
      |> safe_to_string
      assert link == ~s(<a href="/stops/place-sstat">South Station</a>)
    end
  end

  describe "external_link/1" do
    test "Protocol is added when one is not included" do
      assert external_link("http://www.google.com") == "http://www.google.com"
      assert external_link("www.google.com") == "http://www.google.com"
      assert external_link("https://google.com") == "https://google.com"
    end
  end

  describe "subway_name/1" do
    test "All Green line routes display \"Green Line\"" do
      assert subway_name("Green-B") == "Green Line"
      assert subway_name("Green-C") == "Green Line"
      assert subway_name("Green-D") == "Green Line"
      assert subway_name("Green-E") == "Green Line"
    end

    test "Lines show correct display name" do
      assert subway_name("Red Line") == "Red Line"
      assert subway_name("Mattapan") == "Mattapan Trolley"
      assert subway_name("Blue Line") == "Blue Line"
      assert subway_name("Orange Line") == "Orange Line"
    end
  end

  describe "mode_string/1" do
    test "converts the atom to a dash delimted string" do
      assert hyphenated_mode_string(:the_ride) == "the-ride"
      assert hyphenated_mode_string(:bus) == "bus"
      assert hyphenated_mode_string(:subway) == "subway"
      assert hyphenated_mode_string(:commuter_rail) == "commuter-rail"
      assert hyphenated_mode_string(:ferry) == "ferry"
    end
  end

  describe "mode_summaries/2" do
    test "commuter rail summaries only include commuter_rail mode" do
      summaries = mode_summaries(:commuter_rail, {:zone, "7"})
      assert Enum.all?(summaries, fn(summary) -> :commuter_rail in summary.modes end)
    end

    test "Bus summaries return bus single trip information with subway passes" do
      [first | rest] = mode_summaries(:bus)
      assert first.modes == [:bus]
      assert first.duration == :single_trip
      assert Enum.all?(rest, fn summary -> summary.duration in [:week, :month] end)
    end

    test "Bus_subway summaries return both bus and subway information" do
      summaries = mode_summaries(:bus_subway)
      mode_present = fn(summary, mode) -> mode in summary.modes end
      assert Enum.any?(summaries, &(mode_present.(&1,:bus))) && Enum.any?(summaries, &(mode_present.(&1,:subway)))
    end

    test "Ferry summaries with nil fare name return range of fares" do
      fares =
        :ferry
        |> mode_summaries(nil)
        |> Enum.map(fn %Fares.Summary{fares: [{text, prices}]} -> IO.iodata_to_binary([text, " ", prices]) end)

      assert fares == ["All Ferry routes $3.50 - $18.50", "All Ferry routes $84.50 - $308.00"]
    end

    test "Ferry summmaries with a fare name return a single fare" do
      fares =
        :ferry
        |> mode_summaries(:ferry_inner_harbor)
        |> Enum.map(fn %Fares.Summary{fares: [{text, prices}]} -> IO.iodata_to_binary([text, " ", prices]) end)

      assert fares == ["CharlieTicket $3.50", "CharlieTicket $84.50"]
    end
  end

  describe "mode_atom/1" do
    test "Mode atoms do not contain spaces" do
      assert mode_atom("Commuter Rail") == :commuter_rail
      assert mode_atom("Red Line") == :red_line
      assert mode_atom("Ferry") == :ferry
    end
  end

  describe "format_full_date/1" do
    test "formats a date" do
      assert format_full_date(~D[2017-03-31]) == "March 31, 2017"
    end
  end

  describe "cms_static_page_path/2" do
    test "returns the given path as-is", %{conn: conn} do
      assert cms_static_page_path(conn, "/cms/path") == "/cms/path"
    end
  end

  describe "fare_group/1" do
    test "return correct fare group for all modes" do
      assert fare_group(:bus) == "bus_subway"
      assert fare_group(:subway) == "bus_subway"
      assert fare_group(:commuter_rail) == "commuter_rail"
      assert fare_group(:ferry) == "ferry"
    end

    test "return correct fare group when route type given (as integer)" do
      assert fare_group(0) == "bus_subway"
      assert fare_group(1) == "bus_subway"
      assert fare_group(2) == "commuter_rail"
      assert fare_group(3) == "bus_subway"
      assert fare_group(4) == "ferry"
    end
  end

  describe "to_camelcase/1" do
    test "turns a phrase with spaces into camelcased format" do
      assert to_camelcase("Capitalized With Spaces") == "capitalizedWithSpaces"
      assert to_camelcase("Capitalized") == "capitalized"
      assert to_camelcase("Sentence case") == "sentenceCase"
      assert to_camelcase("no words capitalized") == "noWordsCapitalized"
      assert to_camelcase("with_underscores") == "withUnderscores"
    end
  end

  describe "fa/2" do
    test "creates the HTML for a FontAwesome icon" do
      expected = ~s(<i aria-hidden="true" class="fa fa-arrow-right "></i>)

      result = fa("arrow-right")

      assert result |> safe_to_string() == expected
    end

    test "when optional attributes are included" do
      expected = ~s(<i aria-hidden="true" class="fa fa-arrow-right foo" title="title"></i>)

      result = fa("arrow-right", class: "foo", title: "title")

      assert result |> safe_to_string() == expected
    end
  end

  describe "direction_with_headsign/3" do
    test "returns the direction name and headsign when included" do
      actual = safe_to_string(html_escape(direction_with_headsign(%Route{}, 0, "headsign")))
      assert actual =~ "Outbound"
      assert actual =~ "arrow-right"
      assert actual =~ ~s(<span class="sr-only">to</span>)
      assert actual =~ "headsign"
    end

    test "skips the arrow and headsign if the headsign is empty" do
      actual = safe_to_string(html_escape(direction_with_headsign(%Route{}, 0, "")))
      refute actual =~ "arrow-right"
    end
  end

  describe "pretty_date/2" do
    test "it is today when the date given is todays date" do
      assert pretty_date(Util.service_date) == "today"
    end

    test "it abbreviates the month when the date is not today" do
      date = ~D[2017-01-01]
      assert pretty_date(date) == "Jan 1"
    end

    test "it applies custom formatting if provided" do
      date = ~D[2017-01-01]
      assert pretty_date(date, "{Mfull} {D}, {YYYY}") == "January 1, 2017"
    end
  end

  describe "svg/1" do
    test "throw exception for unknown SVG" do
      assert_raise ArgumentError, fn ->
        svg("???")
      end
    end
  end
end
