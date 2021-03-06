import React from "react";
import { mount } from "enzyme";
import Map, { iconOpts, reducer } from "../components/Map";
import {
  MapData,
  MapMarker as Marker
} from "../../leaflet/components/__mapdata";

/* eslint-disable @typescript-eslint/camelcase */
const data: MapData = {
  zoom: 16,
  width: 600,
  tile_server_url: "https://mbta-map-tiles-dev.s3.amazonaws.com",
  polylines: [],
  stop_markers: [
    {
      icon: "stop-circle-bordered-expanded",
      id: "stop-place-alfcl",
      latitude: 42.395428,
      longitude: -71.142483,
      rotation_angle: 0,
      tooltip: null,
      tooltip_text: "Alewife",
      shape_id: "1"
    }
  ],
  markers: [
    {
      icon: "vehicle-bordered-expanded",
      id: "vehicle-R-545CDFC5",
      latitude: 42.39786911010742,
      longitude: -71.13092041015625,
      rotation_angle: 90,
      tooltip_text: "Alewife train is on the way to Alewife",
      tooltip: null
    },
    {
      icon: "stop-circle-bordered-expanded",
      id: "stop-place-alfcl",
      latitude: 42.395428,
      longitude: -71.142483,
      rotation_angle: 0,
      tooltip: null,
      tooltip_text: "Alewife",
      shape_id: "1"
    }
  ],
  height: 600,
  default_center: {
    longitude: -71.05891,
    latitude: 42.360718
  }
};
/* eslint-enable typescript/camelcase */

describe("Schedule Map", () => {
  it("renders", () => {
    const wrapper = mount(<Map data={data} channel="vehicles:Red:0" />);
    expect(() => wrapper.render()).not.toThrow();
  });
});

describe("reducer", () => {
  const newMarker: Marker = {
    icon: "vehicle-bordered-expanded",
    id: "vehicle-R-545CDFC6",
    latitude: 42.39786911010742,
    longitude: -71.13092041015625,
    // eslint-disable-next-line typescript/camelcase
    rotation_angle: 90,
    // eslint-disable-next-line typescript/camelcase
    tooltip_text: "Alewife train is on the way to Alewife",
    tooltip: null,
    // eslint-disable-next-line typescript/camelcase
    shape_id: "1"
  };

  it("resets markers", () => {
    const result = reducer(
      { markers: data.markers, shapeId: "1", channel: "vehicle:1:1" },
      {
        action: {
          event: "reset",
          data: [{ marker: newMarker }]
        },
        channel: "vehicle:1:1"
      }
    );

    expect(result.markers.map(m => m.id)).toEqual([
      data.markers[1].id,
      newMarker.id
    ]);
  });

  it("adds vehicles", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "1" },
      {
        action: { event: "add", data: [{ marker: newMarker }] },
        channel: "vehicle:1:1"
      }
    );
    expect(result.markers.map(m => m.id)).toEqual(
      data.markers.map(m => m.id).concat(newMarker.id)
    );
  });

  it("updates markers", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "1" },
      {
        action: {
          event: "update",
          data: [{ marker: { ...data.markers[0], latitude: 43.0 } }]
        },
        channel: "vehicle:1:1"
      }
    );

    expect(result.markers.map(m => m.id)).toEqual(data.markers.map(m => m.id));
    expect(data.markers[0].latitude).toEqual(42.39786911010742);
    expect(result.markers[0].latitude).toEqual(43.0);
  });

  it("ignores markers from other shapes", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "1" },
      {
        action: {
          event: "update",
          data: [{ marker: { ...data.markers[0], shape_id: "3" } }]
        },
        channel: "vehicle:1:1"
      }
    );

    expect(result.markers).toEqual(data.markers);
  });

  it("ignores markers from other channels", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "2" },
      {
        action: { event: "update", data: [{ marker: data.markers[0] }] },
        channel: "vehicle:1:0"
      }
    );

    expect(result.markers).toEqual(data.markers);
  });

  it("doesn't handle unknown events empty data actions", () => {
    expect(() =>
      reducer(
        { markers: data.markers, channel: "vehicle:1:1", shapeId: "2" },
        {
          // @ts-ignore
          action: { event: "unsupported", data: [] },
          channel: "vehicle:1:1"
        }
      )
    ).toThrowError();
  });

  it("handles empty data actions", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "2" },
      {
        action: { event: "update", data: [] },
        channel: "vehicle:1:1"
      }
    );

    expect(result.markers).toEqual(data.markers);
  });

  it("removes markers", () => {
    const result = reducer(
      { markers: data.markers, channel: "vehicle:1:1", shapeId: "1" },
      {
        action: { event: "remove", data: [data.markers[0].id!] },
        channel: "vehicle:1:1"
      }
    );

    expect(result.markers.map(m => m.id)).toEqual([data.markers[1].id]);
  });
});

describe("iconOpts", () => {
  it("handles stop markers", () => {
    expect(iconOpts(data.markers[1].icon)).toEqual({
      icon_size: [12, 12], // eslint-disable-line @typescript-eslint/camelcase
      icon_anchor: [6, 6] // eslint-disable-line @typescript-eslint/camelcase
    });
  });

  it("throws an error if it received an unknown icon type", () => {
    expect(() => iconOpts("unknown")).toThrowError();
  });

  it("does not throw error when icon is null", () => {
    expect(iconOpts(null)).toEqual({});
  });
});
