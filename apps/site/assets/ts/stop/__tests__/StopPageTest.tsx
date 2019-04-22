import React from "react";
import renderer from "react-test-renderer";
import { mount } from "enzyme";
import StopPage from "../components/StopPage";
import stopData from "./stopData.json";
import { Alert } from "../../__v3api";
import { StopPageData, AlertsTab, StopMapData } from "../components/__stop";
import { MapData } from "../../leaflet/components/__mapdata";
import { createReactRoot } from "../../app/helpers/testUtils";

/* eslint-disable typescript/camelcase */
const mapData: MapData = {
  zoom: 14,
  width: 630,
  tile_server_url: "",
  markers: [
    {
      id: "current-stop",
      latitude: 25,
      longitude: 25,
      icon: null,
      "visible?": true,
      size: "medium",
      tooltip: null,
      z_index: 1
    }
  ],
  default_center: { latitude: 0, longitude: 0 },
  height: 500
};

const initialData: StopMapData = {
  map_data: mapData,
  map_srcset: "",
  map_url: ""
};

const lowAlert: Alert = {
  updated_at: "Updated: 4/11/2019 09:33A",
  severity: 7,
  priority: "low",
  lifecycle: "upcoming",
  active_period: [],
  informed_entity: [],
  id: "00005",
  header: "There is construction at this station.",
  effect: "other",
  description: ""
};
/* eslint-enable typescript/camelcase */

it("it renders", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

  createReactRoot();
  const tree = renderer
    .create(
      <StopPage
        stopPageData={{ ...data, alerts: [lowAlert] }}
        mapId="test"
        mapData={initialData}
      />
    )
    .toJSON();
  expect(tree).toMatchSnapshot();
});

it("it renders the alert tab", () => {
  const data = JSON.parse(JSON.stringify(stopData)) as StopPageData;

  /* eslint-disable typescript/camelcase */
  const alertsTab: AlertsTab = {
    current: {
      alerts: [],
      empty_message: "No current alerts"
    },
    upcoming: {
      alerts: [],
      empty_message: "No upcoming alerts"
    },
    all: {
      alerts: [lowAlert],
      empty_message: "No alerts"
    },
    initial_selected: "all"
  };

  createReactRoot();
  const wrapper = mount(
    <StopPage
      stopPageData={{ ...data, tab: "alerts", alerts_tab: alertsTab }}
      mapId="test"
      mapData={initialData}
    />
  );
  expect(wrapper.find(".m-alerts__time-filters").exists()).toBeTruthy();
  /* eslint-enable typescript/camelcase */
});
