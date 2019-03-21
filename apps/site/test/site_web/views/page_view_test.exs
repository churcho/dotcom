defmodule SiteWeb.PageViewTest do
  use Site.ViewCase, async: true
  alias Plug.Conn

  describe "banners" do
    test "renders _banner.html for important banners" do
      banner = %Content.Banner{
        title: "Important Banner Title",
        blurb: "Uh oh, this is very important!",
        link: %Content.Field.Link{url: "http://example.com/important", title: "Call to Action"},
        utm_url: "http://example.com/important?utm=stuff",
        thumb: %Content.Field.Image{},
        banner_type: :important
      }

      rendered = render_to_string(SiteWeb.PageView, "_banner.html", banner: banner, conn: %Conn{})
      assert rendered =~ "Important Banner Title"
      assert rendered =~ "Uh oh, this is very important!"
      assert rendered =~ "Call to Action"
    end

    test "renders _banner.html for default banners" do
      banner = %Content.Banner{
        title: "Default Banner Title",
        blurb: "This is not as important.",
        link: %Content.Field.Link{url: "http://example.com/default", title: "Call to Action"},
        utm_url: "http://example.com/important?utm=stuff",
        thumb: %Content.Field.Image{},
        banner_type: :default
      }

      rendered = render_to_string(SiteWeb.PageView, "_banner.html", banner: banner, conn: %Conn{})
      assert rendered =~ "Default Banner Title"
      refute rendered =~ "This is not as important."
      refute rendered =~ "Call to Action"
    end
  end

  describe "shortcut_icons/0" do
    test "renders shortcut icons" do
      rendered = SiteWeb.PageView.shortcut_icons() |> Phoenix.HTML.safe_to_string()
      icons = Floki.find(rendered, ".m-homepage__shortcut")
      assert length(icons) == 6
    end
  end

  describe "render_news_entries/1" do
    test "renders news entries", %{conn: conn} do
      now = Util.now()

      routes = [
        %{id: "Red", group: "line", mode: "subway"},
        %{id: "commuter_rail", group: "mode", mode: "subway"},
        %{id: "66", group: "route", mode: "bus"},
        %{id: "silver_line", group: "line", mode: "bus"},
        %{id: "local_bus", group: "custom", mode: "bus"}
      ]

      entries =
        for idx <- 1..5 do
          %Content.Teaser{
            title: "News Entry #{idx}",
            type: :news_entry,
            date: Timex.shift(now, hours: -idx),
            path: "http://example.com/news?utm=stuff",
            routes: [Enum.at(routes, idx - 1)]
          }
        end

      rendered =
        conn
        |> assign(:news, entries)
        |> SiteWeb.PageView.render_news_entries()
        |> Phoenix.HTML.safe_to_string()

      assert rendered |> Floki.find(".c-news-entry") |> Enum.count() == 5
      assert rendered |> Floki.find(".c-news-entry--large") |> Enum.count() == 2
      assert rendered |> Floki.find(".c-news-entry--small") |> Enum.count() == 3

      assert rendered =~ "c-news-entry--red-line"
      assert rendered =~ "c-news-entry--commuter-rail"
      assert rendered =~ "c-news-entry--bus"
      assert rendered =~ "c-news-entry--silver-line"
      assert rendered =~ "c-news-entry--bus"
    end
  end
end
