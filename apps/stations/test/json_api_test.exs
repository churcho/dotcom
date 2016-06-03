defmodule JsonApiTest do
  use ExUnit.Case, async: true

  test ".parse parses a body into a JsonApi struct" do
    body = """
    {"jsonapi":{"version":"1.0"},"included":[{"type":"stop","id":"place-harsq","attributes":{"wheelchair_boarding":1,"name":"Harvard","longitude":-71.118956,"latitude":42.373362}}],"data":{"type":"stop","relationships":{"parent_station":{"data":{"type":"stop","id":"place-harsq"}}},"links":{"self":"/stops/20761"},"id":"20761","attributes":{"wheelchair_boarding":0,"name":"Harvard Upper Busway @ Red Line","longitude":-71.118956,"latitude":42.373362}}}
    """

    assert JsonApi.parse(body) == %JsonApi{
      links: %{},
      data: [
        %JsonApi.Item{
          type: "stop",
          id: "20761",
          attributes: %{
            "name" => "Harvard Upper Busway @ Red Line",
            "wheelchair_boarding" => 0,
            "latitude" => 42.373362,
            "longitude" => -71.118956
          },
          relationships: %{
            "parent_station" => [
              %JsonApi.Item{
                type: "stop",
                id: "place-harsq",
                attributes: %{
                  "name" => "Harvard",
                  "wheelchair_boarding" => 1,
                  "latitude" => 42.373362,
                  "longitude" => -71.118956,
                },
                relationships: %{}
              }
            ]
          }
        }
      ]
    }
  end
end
