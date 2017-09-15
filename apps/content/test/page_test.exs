defmodule Content.PageTest do
  use ExUnit.Case, async: true

  alias Content.CMS.Static

  describe "from_api/1" do
    test "switches on the node type in the json response and returns the proper page struct" do
      assert %Content.BasicPage{} = Content.Page.from_api(Static.basic_page_response())
      assert %Content.Event{} = Content.Page.from_api(List.first(Static.events_response()))
      assert %Content.LandingPage{} = Content.Page.from_api(Static.landing_page_response())
      assert %Content.NewsEntry{} = Content.Page.from_api(List.first(Static.news_response()))
      assert %Content.Person{} = Content.Page.from_api(List.first(Static.people_response()))
      assert %Content.Project{} = Content.Page.from_api(List.first(Static.projects_response()))
      assert %Content.ProjectUpdate{} = Content.Page.from_api(List.first(Static.project_updates_response()))
      assert %Content.Redirect{} = Content.Page.from_api(Static.redirect_response())
    end
  end
end
