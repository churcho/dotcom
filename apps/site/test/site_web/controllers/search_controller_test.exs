defmodule SiteWeb.SearchControllerTest do
  use SiteWeb.ConnCase, async: true
  import Mock

  @params %{"search" => %{"query" => "mbta"}}

  describe "index with params" do
    test "search param", %{conn: conn} do
      conn = get conn, search_path(conn, :index, @params)
      response = html_response(conn, 200)
      # check pagination
      assert response =~ "Showing results 1-10 of 2083"

      # check highlighting
      assert response =~ "solr-highlight-match"

      # check links from each type of document result
      assert response =~ "/people/monica-tibbits-nutt?from=search"
      assert response =~ "/node/1884?from=search"
      assert response =~ "/safety/transit-police/office-the-chief?from=search"
      assert response =~ "/sites/default/files/2017-01/C. Perkins.pdf?from=search"
      assert response =~ "/node/1215?from=search"
      assert response =~ "/fares?a=b&amp;from=search"
    end

    test "include offset", %{conn: conn} do
      params = %{@params | "search" => Map.put(@params["search"], "offset", "3")}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "Showing results 31-40 of 2083"
    end

    test "include filter", %{conn: conn} do
      content_type = %{"event" => "true"}
      params = %{@params | "search" => Map.put(@params["search"], "content_type", content_type)}
      conn = get conn, search_path(conn, :index, params)
      response = html_response(conn, 200)
      assert response =~ "<input checked=\"checked\" id=\"content_type_event\" name=\"search[content_type][event]\" type=\"checkbox\" value=\"true\">"
    end

    test "no matches", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => "empty"}})
      response = html_response(conn, 200)
      assert response =~ "There are no results matching"
    end

    test "empty search query", %{conn: conn} do
      conn = get conn, search_path(conn, :index, %{"search" => %{"query" => ""}})
      response = html_response(conn, 200)
      assert response =~ "empty-search-page"
    end

    test "search server is returning an error", %{conn: conn} do
      with_mock Content.Repo, [search: fn(_, _, _) -> {:error, :error} end] do
        conn = get conn, search_path(conn, :index, @params)
        response = html_response(conn, 200)
        assert response =~ "Whoops"
      end
    end
  end
end
