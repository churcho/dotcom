import React, { ReactElement } from "react";
import RoutePillList from "./RoutePillList";
import { Stop } from "../../__v3api";
import { TypedRoutes } from "./__stop";
import renderSvg from "../../helpers/render-svg";

// @ts-ignore
import streetViewSvg from "../../../static/images/icon-street-view-default.svg";

interface Props {
  routes: TypedRoutes[];
  stop: Stop;
  encoder?: (str: string) => string;
}

const renderAddress = (address: string): ReactElement<HTMLElement> => (
  <div className="m-stop-page__address">
    <h3 className="u-small-caps">Address</h3>
    <div className="h3">{address}</div>
  </div>
);

const latLngString = (stop: Stop): string =>
  `${stop.latitude},${stop.longitude}`;

const locationQuery = (stop: Stop, encoder?: (str: string) => string): string =>
  stop.address && encoder ? encoder(stop.address) : latLngString(stop);

const directionLink = (stop: Stop, encoder?: (str: string) => string): string =>
  `https://www.google.com/maps/dir/?api=1&destination=${locationQuery(
    stop,
    encoder
  )}`;

const streetViewLink = (stop: Stop): string =>
  `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${latLngString(
    stop
  )}`;

const AddressBlock = ({
  routes,
  stop,
  encoder
}: Props): ReactElement<HTMLElement> => (
  <div className="m-stop-page__address-block">
    {stop.address && renderAddress(stop.address)}
    <div className="m-stop-page__address-links">
      <div className="m-stop-page__address-link">
        <a
          href={directionLink(stop, encoder)}
          className="btn btn-primary"
          target="_blank"
          rel="noopener noreferrer"
        >
          Get directions to this station
        </a>
      </div>
      <div className="m-stop-page__address-link">
        <a
          href={streetViewLink(stop)}
          target="_blank"
          rel="noopener noreferrer"
        >
          {renderSvg(
            "c-svg__icon-street-view m-stop-page__street-view-icon",
            streetViewSvg
          )}
          Street View
        </a>
      </div>
    </div>
    <RoutePillList routes={routes} />
  </div>
);

export default AddressBlock;
