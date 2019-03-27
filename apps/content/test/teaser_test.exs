defmodule Content.TeaserTest do
  use ExUnit.Case, async: true

  alias Content.CMS.Static
  alias Content.Field.Image
  alias Content.Teaser

  test "parses a teaser item into %Content.Teaser{}" do
    [raw | _] = Static.teaser_response()
    teaser = Teaser.from_api(raw)

    assert %Teaser{
             id: id,
             type: type,
             path: path,
             image: image,
             text: text,
             title: title,
             date: date,
             topic: topic,
             routes: routes
           } = teaser

    assert id == 3661
    assert type == :project
    assert path == "/projects/green-line-d-track-and-signal-replacement"
    assert %Image{url: "http://" <> _, alt: "Tracks at Riverside"} = image
    assert text =~ "This project is part of"
    assert title == "Green Line D Track and Signal Replacement"
    assert topic == nil
    assert %Date{} = date
    assert [%{id: "Green-D"}] = routes
  end

  test "uses field_posted_on date for news entries" do
    raw = Static.teaser_response() |> Enum.at(5)

    teaser = Teaser.from_api(raw)
    assert teaser.date.day == 01
  end

  test "sets date to null if CMS date format is invalid" do
    assert Static.teaser_response()
           |> List.first()
           |> Map.put("updated", "invalid")
           |> Teaser.from_api()
           |> Map.get(:date) == nil

    assert Static.teaser_response()
           |> List.last()
           |> Map.put("start", "invalid")
           |> Teaser.from_api()
           |> Map.get(:date) == nil
  end

  test "uses updated field as date for projects" do
    teaser =
      Static.teaser_project_response()
      |> List.first()
      |> Teaser.from_api()

    assert teaser.id == 3661
    assert teaser.date == ~D[2018-11-30]
  end

  test "uses posted field as date for news" do
    news_entry =
      Static.teaser_news_entry_response()
      |> List.first()
      |> Teaser.from_api()

    assert news_entry.id == 3944
    assert news_entry.date == ~D[2018-12-04]

    project_update =
      Static.teaser_project_update_response()
      |> List.first()
      |> Teaser.from_api()

    assert project_update.id == 3005
    assert project_update.date == ~D[2019-02-18]
  end

  test "uses start field as date for events and includes time" do
    teaser =
      Static.teaser_event_response()
      |> List.first()
      |> Teaser.from_api()

    assert teaser.id == 3911
    assert teaser.date == Timex.parse!("2019-12-16T12:00:00Z", "{ISO:Extended:Z}")
  end

  test "uses created date for content types without explicit date fields" do
    teaser =
      Static.teaser_basic_page_response()
      |> List.first()
      |> Teaser.from_api()

    assert teaser.id == 3862
    assert teaser.date == ~D[2018-10-30]
  end

  test "parses a complete location into a bullet-separated string" do
    teaser =
      Static.teaser_event_response()
      |> List.first()
      |> Teaser.from_api()

    assert teaser.id == 3911

    assert teaser.location ==
             "State Transportation Building • 10 Park Plaza, 2nd Floor, Transportation Board Room • Boston • MA"
  end

  test "parses an incomplete location into a bullet-separated string" do
    assert Static.teaser_event_response()
           |> List.first()
           |> Map.put("location", "||Quincy|MA")
           |> Teaser.from_api()
           |> Map.get(:location) == "Quincy • MA"
  end

  test "stores a list of all attached gtfs ids for later usage" do
    routes =
      Static.teaser_response()
      |> Enum.at(1)
      |> Teaser.from_api()
      |> Map.get(:routes)

    assert [%{id: "CR-Lowell"}, %{id: "CR-Providence"}] = routes
  end
end
