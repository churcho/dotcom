import React, { ReactElement } from "react";
import { Route } from "../../__v3api";
import { TypedRoutes } from "./__stop";
import { breakTextAtSlash } from "../../helpers/text";

interface RoutePillListProps {
  routes: TypedRoutes[];
}

interface RoutePillProps {
  route: Route;
}

const routeToClass = (name: string): string =>
  name.toLowerCase().replace(" ", "-");

const busName = (name: string): string =>
  name.startsWith("SL") ? "silver-line" : "bus";

const modeNameForBg = ({ name, type }: Route): string => {
  switch (type) {
    case 0:
    case 1:
      return routeToClass(name);
    case 2:
      return "commuter-rail";
    case 4:
      return "ferry";
    default:
      return busName(name);
  }
};

const modeBgClass = (route: Route): string => `u-bg--${modeNameForBg(route)}`;

const RoutePill = ({ route }: RoutePillProps): ReactElement<HTMLElement> => (
  <a
    href={`/schedules/${route.id}`}
    className={`
      m-stop-page__header-feature
      m-stop-page__header-description
      u-small-caps
      ${modeBgClass(route)}
    `}
  >
    {breakTextAtSlash(route.name)}
  </a>
);

const RoutePillList = ({
  routes
}: RoutePillListProps): ReactElement<HTMLElement> => (
  <div className="m-route-pills">
    {routes.map(typedRoute => (
      <div
        key={typedRoute.group_name}
        className={`m-route-pills--${typedRoute.group_name}`}
      >
        {typedRoute.routes.map(routeWithDirections => (
          <RoutePill
            key={routeWithDirections.route.id}
            route={routeWithDirections.route}
          />
        ))}
      </div>
    ))}
  </div>
);

export default RoutePillList;
