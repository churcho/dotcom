import React, { ReactElement } from "react";
import ExpandableBlock from "../../app/ExpandableBlock";
import { BikeStorage, Stop } from "../../__v3api";
// @ts-ignore
import bikeIconSvg from "../../../static/images/icon-bikes-default.svg";

interface Props {
  stop: Stop;
}

const bikeStorageType = (storage: BikeStorage): string => {
  switch (storage) {
    case "bike_storage_rack":
      return "Regular bike racks";
    case "bike_storage_rack_covered":
      return "Covered bike racks";
    case "bike_storage_cage":
      return "Pedal and Park";
    default:
      return "Regular bike racks";
  }
};

const pedalAndParkInfo = (): ReactElement<HTMLElement> => (
  <div className="m-stop-page__pedal-and-park">
    {
      "Access to secure bike parking is available for registered CharlieCard holders."
    }
    <div>
      <a href="https://bc.mbta.com/riding_the_t/bikes/register/Default.asp">
        Register your CharlieCard for bike parking
      </a>
    </div>
  </div>
);
const renderStorage = (stop: Stop): ReactElement<HTMLElement> => (
  <>
    <p>{`${stop.name} has the following bike storage features:`}</p>
    <ul className="m-stop-page__bike-storage-list">
      {stop.bike_storage.map((storage: BikeStorage) => {
        const bikeStorage = bikeStorageType(storage);
        if (bikeStorage === "Pedal and Park") {
          return (
            <div key="pedal-and-park">
              <li className="m-stop-page__bike-storage-list-item">
                {bikeStorage}
              </li>
              {pedalAndParkInfo()}
            </div>
          );
        }
        return (
          <li className="m-stop-page__bike-storage-list-item" key={storage}>
            {bikeStorage}
          </li>
        );
      })}
    </ul>
  </>
);

const stopOrStation = (stop: Stop): string =>
  stop["station?"] ? "station" : "stop";

const BikeStorageInfo = ({ stop }: Props): ReactElement<HTMLElement> => (
  <ExpandableBlock
    initiallyExpanded={false}
    id="bikes"
    header={{
      text: "Bikes",
      iconSvgText: bikeIconSvg
    }}
  >
    <>
      {stop.bike_storage.length > 0 ? (
        renderStorage(stop)
      ) : (
        <p>{`There is no bike parking information available for this ${stopOrStation(
          stop
        )}.`}</p>
      )}
      <a href="/bikes" className="c-call-to-action">
        Learn more about bikes and the T
      </a>
    </>
  </ExpandableBlock>
);

export default BikeStorageInfo;
