defmodule SiteWeb.ScheduleController.CMSTest do
  use SiteWeb.ConnCase

  alias Content.Teaser
  alias Plug.Conn
  alias Routes.Route
  alias SiteWeb.ScheduleController.CMS

  describe "call/1" do
    test "assigns CMS content to conn", %{conn: conn} do
      conn =
        conn
        |> Conn.assign(:route, %Route{id: "Red", type: 1})
        |> CMS.call([])

      assert %Teaser{} = conn.assigns.featured_content
      assert %URI{query: query} = URI.parse(conn.assigns.featured_content.path)

      assert URI.decode_query(query) == %{
               "utm_campaign" => "curated-content",
               "utm_content" => "Green Line D Track and Signal Replacement",
               "utm_medium" => "project",
               "utm_source" => "schedule",
               "utm_term" => "subway"
             }

      assert [news | _] = conn.assigns.news
      assert %Teaser{} = news
      assert %URI{query: query} = URI.parse(news.path)

      assert URI.decode_query(query) == %{
               "utm_campaign" => "curated-content",
               "utm_content" => "MBTA Awards Signal Upgrade Contract for Red and Orange Lines",
               "utm_medium" => "news",
               "utm_source" => "schedule",
               "utm_term" => "subway"
             }
    end
  end
end
