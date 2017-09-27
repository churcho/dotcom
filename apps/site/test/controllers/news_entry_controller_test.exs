defmodule Site.NewsEntryControllerTest do
  use Site.ConnCase, async: true
  import Site.PageHelpers, only: [breadcrumbs_include?: 2]

  describe "GET index" do
    test "renders a list of news entries", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index)

      body = html_response(conn, 200)
      assert body =~ "News"
      assert breadcrumbs_include?(body, "News")
    end

    test "supports pagination", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index, page: 2)

      body = html_response(conn, 200)
      assert body =~ "Previous"
      assert body =~ news_entry_path(conn, :index, page: 1)
      assert body =~ "Next"
      assert body =~ news_entry_path(conn, :index, page: 3)
    end
  end

  describe "GET show" do
    test "renders a news entry", %{conn: conn} do
      news_entry = news_entry_factory()
      news_entry_title = Phoenix.HTML.safe_to_string(news_entry.title)

      conn = get conn, news_entry_path(conn, :show, news_entry.id)

      body = html_response(conn, 200)
      assert body =~ Phoenix.HTML.safe_to_string(news_entry.title)
      assert body =~ Phoenix.HTML.safe_to_string(news_entry.body)
      assert body =~ Phoenix.HTML.safe_to_string(news_entry.more_information)
      assert breadcrumbs_include?(body, ["News", news_entry_title])
    end

    test "includes Recent News suggestions", %{conn: conn} do
      news_entry = news_entry_factory()

      conn = get conn, news_entry_path(conn, :show, news_entry.id)

      body = html_response(conn, 200)
      assert body =~ "Recent News on the T"
      assert body =~ "MBTA Urges Customers to Stay Connected This Winter"
      assert body =~ "FMCB approves Blue Hill Avenue Station on the Fairmount Line"
      assert body =~ "MBTA Urges Customers to Stay Connected This Summer"
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "invalid")
      assert conn.status == 404
    end
  end
end
