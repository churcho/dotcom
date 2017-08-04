defmodule Content.Field.Link do
  @moduledoc """
  Represents the "Link" field type associated with various content types in the CMS
  """

  defstruct [:title, url: "http://example.com"]

  @type t :: %__MODULE__{
    title: String.t | nil,
    url: String.t,
  }

  @spec from_api(map) :: t
  def from_api(data) do
    %__MODULE__{
      title: field_value(data, "title"),
      url: parse_uri(data),
    }
  end

  @spec parse_uri(map) :: String.t | nil
  defp parse_uri(data) do
    case data["uri"] do
      "internal:" <> relative_path -> relative_path
      url -> url
    end
  end
end
