defmodule Content.HelpersTest do
  use ExUnit.Case, async: true
  import Content.ImageHelpers, only: [site_app_domain: 0]

  import Content.Helpers

  describe "rewrite_url/1" do
    test "rewrites when the URL has query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar?baz=quux")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar?baz=quux"])
    end

    test "rewrites when the URL has no query params" do
      rewritten = rewrite_url("http://test-mbta.pantheonsite.io/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end

    test "rewrites the URL for https" do
      rewritten = rewrite_url("https://example.com/foo/bar")
      assert rewritten == Content.Config.apply(:static, ["/foo/bar"])
    end

    test "rewrites the URL to use the Site app host" do
      rewritten = rewrite_url("https://example.com/foo/bar")
      assert rewritten == "http://#{site_app_domain()}/foo/bar"
    end
  end

  describe "parse_image/2" do
    test "parses the image data" do
      data = %{
        "field_my_image" => [%{
          "alt" => "Picture of a barn",
          "url" => "http://cms/files/barn.jpg",
        }]
      }

      assert parse_image(data, "field_my_image") == %Content.Field.Image{
        alt: "Picture of a barn",
        url: "http://#{site_app_domain()}/files/barn.jpg"
      }
    end

    test "when the specified field is not present" do
      assert parse_image(%{}, "missing_field") == nil
    end
  end

  describe "parse_images/2" do
    test "parses image data with multiple images" do
      data = %{
        "field_with_images" => [
          %{
            "alt" => "Picture of a barn",
            "url" => "/files/barn.jpg",
          },
          %{
            "alt" => "Picture of a horse",
            "url" => "/files/horse.jpg",
          }
        ]
      }

      expected_result = [
        %Content.Field.Image{
          alt: "Picture of a barn",
          url: "http://#{site_app_domain()}/files/barn.jpg"
        },
        %Content.Field.Image{
          alt: "Picture of a horse",
          url: "http://#{site_app_domain()}/files/horse.jpg"
        }
      ]

      assert parse_images(data, "field_with_images") == expected_result
    end

    test "when the specified field is not present" do
      assert parse_images(%{}, "missing_field") == []
    end
  end

  describe "parse_path_alias/1" do
    test "it parses a path alias when present" do
      data = %{
        "path" => [
          %{
            "alias" => "/pretty/url/alias"
          }
        ]
      }

      assert "/pretty/url/alias" == parse_path_alias(data)
    end

    test "returns nil if no path alias present" do
      data = %{"something" => "else"}
      assert nil == parse_path_alias(data)
    end
  end

  describe "parse_link/2" do
    test "it parses a link field into a Link" do
      data = %{
        "field_my_link" => [%{
          "title" => "This is the link text",
          "uri" => "internal:/this/is/the/link/url"
        }]
      }

      assert %Content.Field.Link{
        title: "This is the link text",
        url: "/this/is/the/link/url"
      } = parse_link(data, "field_my_link")
    end

    test "it returns nil if unexpected format" do
      data = %{
        "field_my_link" => %{
          hmmm: "what is this?"
        }
      }

      assert parse_link(data, "field_my_link") == nil
    end
  end

  describe "parse_date/2" do
    test "parses a date string to a date" do
      map = %{"posted_on" => [%{"value" => "2017-01-01"}]}

      assert parse_date(map, "posted_on") == ~D[2017-01-01]
    end

    test "when the date string cannot be converted to a date" do
      map = %{"posted_on" => [%{"value" => ""}]}
      assert parse_date(map, "posted_on") == nil
    end

    test "when the field is missing" do
      assert parse_date(%{}, "posted_on") == nil
    end
  end

  describe "int_or_string_to_int/1" do
    test "converts appropriately or leaves alone" do
      assert int_or_string_to_int(5) == 5
      assert int_or_string_to_int("5") == 5
    end

    test "handles invalid string" do
      assert int_or_string_to_int("foo") == nil
    end

    test "handles nil" do
      assert int_or_string_to_int(nil) == nil
    end
  end

  describe "handle_html/1" do
    test "removes unsafe html tags from safe content" do
      html = "<h1>hello!<script>code</script></h1>"
      assert handle_html(html) == {:safe, "<h1>hello!code</h1>"}
    end

    test "allows valid HTML5 tags" do
      html = "<p>Content</p>"
      assert handle_html(html) == {:safe, "<p>Content</p>"}
    end

    test "rewrites static file links" do
      html = "<img src=\"/sites/default/files/converted.jpg\">"
      assert handle_html(html) == {:safe, "<img src=\"http://localhost:4001/sites/default/files/converted.jpg\" />"}
    end

    test "allows an empty string" do
      assert handle_html("") == {:safe, ""}
    end

    test "allows nil" do
      assert handle_html(nil) == {:safe, ""}
    end
  end

  describe "parse_paragraphs/1" do
    test "it parses different kinds of paragraphs" do
      api_data = %{"field_paragraphs" => [
        %{
          "type" => [%{"target_id" => "custom_html"}],
          "status" => [%{"value" => 1}],
          "field_custom_html_body" =>  [%{"value" => "some HTML"}]
        },
        %{
          "type" => [%{"target_id" => "title_card_set"}],
          "status" => [%{"value" => 1}],
          "field_title_cards" => [%{
            "type" => [%{"target_id" => "title_card"}],
            "field_title_card_body" => [%{"value" => "body"}],
            "field_title_card_link" => [%{"uri" => "internal:/foo/bar"}],
            "field_title_card_title" => [%{"value" => "title"}]
          }],
        }
      ]}

      parsed = parse_paragraphs(api_data)

      assert parsed == [
        %Content.Paragraph.CustomHTML{body: Phoenix.HTML.raw("some HTML")},
        %Content.Paragraph.TitleCardSet{
          title_cards: [%Content.Paragraph.TitleCard{
            body: Phoenix.HTML.raw("body"),
            title: "title",
            link: %Content.Field.Link{
              url: "/foo/bar",
            }
          }]
        }
      ]
    end
    
    test "it skips paragraphs that are unpublished" do
      map_data = %{"field_paragraphs" => [
        %{
          "type" => [%{"target_id" => "custom_html"}],
          "status" =>  [%{"value" => 1}]
        },
        %{
          "type" => [%{"target_id" => "custom_html"}],
          "status" =>  [%{"value" => 0}]
        },
        %{
          "type" => [%{"target_id" => "title_card_set"}],
          "status" =>  [%{"value" => 1}]
        },
        %{
          "type" => [%{"target_id" => "title_card_set"}],
          "status" =>  [%{"value" => 0}]
        }
      ]}

      parsed_map = parse_paragraphs(map_data)

      assert parsed_map == [
        %{"field_paragraphs" => [
          %{
            "type" => [%{"target_id" => "custom_html"}],
            "status" =>  [%{"value" => 1}]
          },
          %{
            "type" => [%{"target_id" => "title_card_set"}],
            "status" =>  [%{"value" => 1}]
          }
        ]}
      ]
    end
  end
end
