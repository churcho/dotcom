defmodule Content.Page do
  @moduledoc """
  Parses the api data to a struct, based on the api data's content type.
  """

  alias Content.{Paragraph, Paragraph.ContentList}

  @type t ::
          Content.BasicPage.t()
          | Content.Event.t()
          | Content.LandingPage.t()
          | Content.NewsEntry.t()
          | Content.Person.t()
          | Content.Project.t()
          | Content.ProjectUpdate.t()
          | Content.Redirect.t()

  @doc """
  Expects parsed json from drupal CMS. Should be one item (not array of items)
  """
  @spec from_api(map) :: t
  def from_api(data) do
    data
    |> parse()
    |> fetch_content_lists()
  end

  defp parse(%{"type" => [%{"target_id" => "page"}]} = api_data) do
    Content.BasicPage.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "event"}]} = api_data) do
    Content.Event.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "landing_page"}]} = api_data) do
    Content.LandingPage.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "news_entry"}]} = api_data) do
    Content.NewsEntry.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "person"}]} = api_data) do
    Content.Person.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "project"}]} = api_data) do
    Content.Project.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "project_update"}]} = api_data) do
    Content.ProjectUpdate.from_api(api_data)
  end

  defp parse(%{"type" => [%{"target_id" => "redirect"}]} = api_data) do
    Content.Redirect.from_api(api_data)
  end

  @spec fetch_content_lists(t) :: t
  defp fetch_content_lists(%{paragraphs: paragraphs} = struct) when is_list(paragraphs) do
    paragraphs_with_lists =
      paragraphs
      |> Enum.map(&content_list_async/1)
      |> Util.async_with_timeout(paragraphs, __MODULE__)

    %{struct | paragraphs: paragraphs_with_lists}
  end

  defp fetch_content_lists(struct) do
    struct
  end

  @spec content_list_async(Paragraph.t()) :: (() -> Paragraph.t())
  defp content_list_async(%ContentList{} = content_list) do
    fn -> ContentList.fetch_teasers(content_list) end
  end

  defp content_list_async(not_a_content_list) do
    fn -> not_a_content_list end
  end
end
