defmodule Content.WhatsHappeningItem do
  import Content.Helpers, only: [field_value: 2, parse_link_type: 2]

  defstruct [blurb: "", url: "", thumb: nil, thumb_2x: nil]

  @type t :: %__MODULE__{
    blurb: String.t,
    url: String.t,
    thumb: Content.Field.Image.t,
    thumb_2x: Content.Field.Image.t | nil
  }

  @spec from_api(map) :: t
  def from_api(%{} = data) do
    %__MODULE__{
      blurb: field_value(data, "field_wh_blurb"),
      url: parse_link_type(data, "field_wh_link"),
      thumb: parse_image(data["field_wh_thumb"]),
      thumb_2x: parse_image(data["field_wh_thumb_2x"])
    }
  end

  @spec parse_image([map]) :: Content.Field.Image.t | nil
  defp parse_image([%{} = api_image]), do: Content.Field.Image.from_api(api_image)
  defp parse_image(_), do: nil
end
