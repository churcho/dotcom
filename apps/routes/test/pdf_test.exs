defmodule Routes.PdfTest do
  use ExUnit.Case, async: true
  import Routes.Pdf
  alias Routes.Route

  describe "dated_urls/2" do
    test "given a date, returns upcoming schedule PDFs" do
      route = %Route{id: "CR-Fairmount"}
      expected = [
        {~D[2017-01-01], "/sites/default/files/route_pdfs/fairmount.pdf"},
        {~D[2017-05-22], "/sites/default/files/route_pdfs/Fairmont%20WEB%20052217%20V1.pdf"},
      ]
      actual = dated_urls(route, ~D[2017-03-15])

      assert actual == expected
    end

    test "filters out schedules once a new one is in effect" do
      route = %Route{id: "CR-Worcester"}
      expected = [
        {~D[2017-05-22], "/sites/default/files/route_pdfs/Worcester%20WEB%20052217%20V1(1).pdf"}
      ]
      assert dated_urls(route, ~D[2017-05-22]) == expected
      assert dated_urls(route, ~D[2017-05-23]) == expected
    end

    test "returns an nil, nil if there isn't a matching route" do
      route = %Route{id: "nonexistent"}
      assert dated_urls(route, ~D[2017-01-01]) == []
    end
  end

  describe "all_pdfs_for_route/2" do
    test "adds custom pdfs to end of dated pdfs" do
      route = %Route{id: "CR-Worcester"}
      dated_pdf_url = "/sites/default/files/route_pdfs/Worcester%20WEB%20052217%20V1(1).pdf"
      custom_pdf_url = "/sites/default/files/route_pdfs/southstation_backbay.pdf"
      assert [{_dated_text, ^dated_pdf_url}, {_custom_text, ^custom_pdf_url}] = all_pdfs_for_route(route, ~D[2017-05-23])
    end
  end
end
