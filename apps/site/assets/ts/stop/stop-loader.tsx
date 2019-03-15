import React from "react";
import ReactDOM from "react-dom";
import StopPage from "./components/StopPage";
import { StopPageData, StopMapData } from "./components/__stop";
import { doWhenGoogleMapsIsReady } from "../../js/google-maps-loaded";

const render = (): void => {
  const stopPageDataEl = document.getElementById("js-stop-page-data");
  const mapDataEl = document.getElementById("js-stop-map-data");
  if (!stopPageDataEl || !mapDataEl) return;
  const stopPageData = JSON.parse(stopPageDataEl.innerHTML) as StopPageData;
  const mapId = stopPageDataEl.getAttribute("data-for") as string;
  const mapData = JSON.parse(mapDataEl.innerHTML) as StopMapData;
  ReactDOM.render(
    <StopPage stopPageData={stopPageData} mapId={mapId} mapData={mapData} />,
    document.getElementById("react-root")
  );
};

const renderMap = (): void => {
  doWhenGoogleMapsIsReady(() => {
    render();
  });
};

export const onLoad = (): void => {
  renderMap();
};

export default () => {
  document.addEventListener("turbolinks:load", onLoad as EventListener);
  return true;
};
