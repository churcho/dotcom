import React, { ReactElement } from "react";
import { Stop, Route, DirectionId } from "../../__v3api";
import { RouteWithDirection } from "./__stop";
import { modeIcon } from "../../helpers/icon";
import accessible from "./StopAccessibilityIcon";

const formatMilesToFeet = (miles: number): number => Math.floor(miles * 5280.0);

const routeNameBasedOnDirection = (
  route: Route,
  directionId: DirectionId | null
): string =>
  directionId === null
    ? route.long_name
    : // eslint-disable-next-line typescript/camelcase
      route.direction_destinations[directionId];

interface Props {
  stop: Stop;
  routesWithDirection?: RouteWithDirection[];
  routes?: Route[];
  distance?: number;
}

const StopCard = ({
  stop,
  distance,
  routesWithDirection = [],
  routes = []
}: Props): ReactElement<HTMLElement> => {
  const routesToRender =
    routesWithDirection.length === 0 && routes.length > 0
      ? routes.map(route => ({
          route,
          // eslint-disable-next-line typescript/camelcase
          direction_id: null
        }))
      : routesWithDirection;

  return (
    <div className="c-stop-card">
      {distance && (
        <span className="c-stop-card__distance">
          {formatMilesToFeet(distance)} ft
        </span>
      )}
      <a className="c-stop-card__stop-name" href={`/stops-v2/${stop.id}`}>
        {stop.name}
      </a>
      {accessible(stop)}
      {routesToRender &&
        routesToRender.map(({ route, direction_id: directionId }) => (
          <div
            className="c-stop-card__route"
            key={`suggestedTransferRoute${route.id}`}
          >
            {route.type === 3 && !route.name.startsWith("SL") ? (
              <div className="c-stop-card__bus-pill u-bg--bus u-small-class">
                {route.name}
              </div>
            ) : (
              modeIcon(route.id)
            )}
            <a
              href={`/schedules/${route.id}${
                directionId !== null ? `?direction_id=${directionId}` : ""
              }`}
              className="c-stop-card__route-link"
            >
              {routeNameBasedOnDirection(route, directionId)}
            </a>
          </div>
        ))}
    </div>
  );
};

export default StopCard;
