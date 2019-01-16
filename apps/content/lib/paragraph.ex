defmodule Content.Paragraph do
  @moduledoc """

  This module represents the suite of paragraph types that we support on Drupal.
  To add a new Drupal paragraph type, say MyPara, that should show up on pages
  via Phoenix, make the following changes:

  * Pull the most recent content from the CMS. Locally, update the
    /cms/style-guide/paragraphs page, which demonstrates all our paragraphs,
    to include this new paragraph.
  * Load /cms/style-guide/paragraphs?_format=json from the CMS and update
    /cms/style-guide/paragraphs.json.
  * Create a new module, Content.Paragraph.MyPara in lib/paragraph/my_para.ex.
  * Create a _my_para.html.eex partial (filename pattern must match module name)
  * Add that type to Content.Paragraph.t here.
  * Update this module's from_api/1 function to dispatch to the MyPara.from_api
  * Update Content.ParagraphTest to ensure it is parsed correctly
  * Update Site.ContentViewTest to ensure it is rendered correctly
  * After the code is merged and deployed, update /cms/style-guide/paragraphs
    on the live CMS
  """

  alias Content.Paragraph.{
    Accordion,
    Callout,
    ColumnMulti,
    CustomHTML,
    DescriptionList,
    DescriptiveLink,
    FareCard,
    FilesGrid,
    PeopleGrid,
    TitleCardSet,
    Unknown,
    UpcomingBoardMeetings
  }

  @type t ::
          Accordion.t()
          | Callout.t()
          | ColumnMulti.t()
          | CustomHTML.t()
          | DescriptionList.t()
          | DescriptiveLink.t()
          | FareCard.t()
          | FilesGrid.t()
          | PeopleGrid.t()
          | TitleCardSet.t()
          | Unknown.t()
          | UpcomingBoardMeetings.t()

  @types [
    Accordion,
    Callout,
    ColumnMulti,
    CustomHTML,
    DescriptionList,
    DescriptiveLink,
    FareCard,
    FilesGrid,
    PeopleGrid,
    TitleCardSet,
    Unknown,
    UpcomingBoardMeetings
  ]

  @spec from_api(map) :: t
  def from_api(%{"type" => [%{"target_id" => "entity_reference"}]} = para) do
    Callout.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "custom_html"}]} = para) do
    CustomHTML.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "description_list"}]} = para) do
    DescriptionList.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "fare_card"}]} = para) do
    FareCard.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "files_grid"}]} = para) do
    FilesGrid.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "multi_column"}]} = para) do
    ColumnMulti.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "people_grid"}]} = para) do
    PeopleGrid.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "tabs"}]} = para) do
    Accordion.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "title_card"}]} = para) do
    DescriptiveLink.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "title_card_set"}]} = para) do
    TitleCardSet.from_api(para)
  end

  def from_api(%{"type" => [%{"target_id" => "upcoming_board_meetings"}]} = para) do
    UpcomingBoardMeetings.from_api(para)
  end

  def from_api(unknown_paragraph_type) do
    Unknown.from_api(unknown_paragraph_type)
  end

  def get_types, do: @types

  def right_rail?(%{right_rail: true}), do: true
  def right_rail?(_), do: false
end
