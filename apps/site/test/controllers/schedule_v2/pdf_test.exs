defmodule Site.ScheduleV2Controller.PdfTest do
  use Site.ConnCase, async: true

  test "redirects to PDF for route when present", %{conn: conn} do
    route_id = "CR-Fitchburg"
    conn = get(conn, route_pdf_path(conn, :pdf, route_id))
    [{_date, expected_url} | _] = Routes.Pdf.dated_urls(route_id, conn.assigns.date)
    assert redirected_to(conn, 302) == static_url(conn, expected_url)
  end

  test "renders 404 if route doesn't exist", %{conn: conn} do
    conn = get(conn, route_pdf_path(conn, :pdf, "Nonexistent"))
    assert html_response(conn, 404)
  end

  test "renders 404 if route exists but does not have PDF", %{conn: conn} do
    # 195 is a secret route - https://en.wikipedia.org/wiki/List_of_MBTA_bus_routes#195
    route_id = "195"
    conn = get(conn, route_pdf_path(conn, :pdf, route_id))
    assert html_response(conn, 404)
    conn = get(conn, route_pdf_path(conn, :pdf, route_id, date: "2017-01-01"))
    assert html_response(conn, 404)
  end

  test "redirects to a newer URL given a date", %{conn: conn} do
    route_id = "CR-Lowell"
    [{first_date, first_url}, {second_date, second_url} | _] = Routes.Pdf.dated_urls(route_id, ~D[2017-01-01])

    conn = get(conn, route_pdf_path(conn, :pdf, route_id, date: Date.to_iso8601(first_date)))
    assert redirected_to(conn, 302) == static_url(conn, first_url)

    conn = get(conn, route_pdf_path(conn, :pdf, route_id, date: Date.to_iso8601(second_date)))
    assert redirected_to(conn, 302) == static_url(conn, second_url)
  end
end
