import React, { ReactElement, useState, ChangeEvent } from "react";
import { EnhancedRoute, DirectionId } from "../../__v3api";
import {
  SimpleStop,
  SimpleStopMap,
  RoutePatternsByDirection,
  ServiceInSelector,
  ScheduleNote as ScheduleNoteType
} from "./__schedule";
import { handleReactEnterKeyPress } from "../../helpers/keyboard-events";
import icon from "../../../static/images/icon-schedule-finder.svg";
import renderSvg from "../../helpers/render-svg";
import Modal from "../../components/Modal";
import SelectContainer from "./schedule-finder/SelectContainer";
import ErrorMessage from "./schedule-finder/ErrorMessage";
import OriginModalContent from "./schedule-finder/OriginModalContent";
import ScheduleModalContent from "./schedule-finder/ScheduleModalContent";

interface Props {
  services: ServiceInSelector[];
  directionId: DirectionId;
  route: EnhancedRoute;
  stops: SimpleStopMap;
  routePatternsByDirection: RoutePatternsByDirection;
  today: string;
  scheduleNote: ScheduleNoteType | null;
}

export type SelectedDirection = 0 | 1 | null;
export type SelectedOrigin = string | null;

export interface UserInput {
  route: string;
  origin: string;
  date: string;
  direction: SelectedDirection;
}

interface State {
  directionError: boolean;
  modalId: string | null;
  modalOpen: boolean;
  originError: boolean;
  originSearch: string;
  selectedDirection: SelectedDirection;
  selectedOrigin: SelectedOrigin;
  selectedService: string | null;
}

const parseSelectedDirection = (value: string): SelectedDirection => {
  if (value === "0") return 0;
  return 1;
};

export const stopListOrder = (
  stops: SimpleStopMap,
  selectedDirection: SelectedDirection,
  directionId: DirectionId
): SimpleStop[] =>
  selectedDirection !== null ? stops[selectedDirection] : stops[directionId];

const ScheduleFinder = ({
  directionId,
  route,
  services,
  stops,
  routePatternsByDirection,
  today,
  scheduleNote
}: Props): ReactElement<HTMLElement> => {
  const {
    direction_destinations: directionDestinations,
    direction_names: directionNames
  } = route;

  const validDirections = ([0, 1] as DirectionId[]).filter(
    direction => directionNames[direction] !== null
  );

  const [state, setState] = useState<State>({
    directionError: false,
    originError: false,
    originSearch: "",
    modalOpen: false,
    modalId: null,
    selectedDirection: validDirections.length === 1 ? validDirections[0] : null,
    selectedOrigin: null,
    selectedService: null
  });

  const handleUpdateOriginSearch = (
    event: ChangeEvent<HTMLInputElement>
  ): void => {
    setState({
      ...state,
      originSearch: event.target.value
    });
  };

  const handleSubmitForm = (): void => {
    if (state.selectedDirection === null || state.selectedOrigin === null) {
      setState({
        ...state,
        selectedOrigin: state.selectedOrigin,
        directionError: state.selectedDirection === null,
        originError: state.selectedOrigin === null
      });
      return;
    }

    setState({
      ...state,
      directionError: false,
      originError: false,
      modalId: "schedule",
      modalOpen: true
    });
  };

  const handleChangeDirection = (direction: SelectedDirection): void => {
    setState({ ...state, selectedDirection: direction, selectedOrigin: null });
  };

  const handleChangeOrigin = (
    origin: SelectedOrigin,
    autoSubmit: boolean
  ): void => {
    if (state.selectedDirection !== null && autoSubmit) {
      setState({
        ...state,
        selectedOrigin: origin,
        modalId: "schedule",
        directionError: false,
        originError: false
      });
    } else {
      setState({
        ...state,
        selectedOrigin: origin
      });
    }
  };

  const handleOriginSelectClick = (): void => {
    if (state.selectedDirection === null) {
      setState({
        ...state,
        directionError: true
      });
      return;
    }

    setState({
      ...state,
      modalOpen: true,
      modalId: "origin"
    });
  };

  return (
    <div className="schedule-finder">
      <h2 className="h3 schedule-finder__heading">
        {renderSvg("c-svg__icon", icon)} Schedule Finder
      </h2>
      <ErrorMessage
        directionError={state.directionError}
        originError={state.originError}
      />
      <div>
        Choose a stop to get schedule information and real-time departure
        predictions.
      </div>
      <label className="schedule-finder__label" htmlFor="sf_direction_select">
        Choose a direction
      </label>
      <SelectContainer
        error={state.directionError}
        id="sf_direction_select_container"
      >
        <select
          id="sf_direction_select"
          className="c-select-custom"
          value={
            state.selectedDirection !== null ? state.selectedDirection : ""
          }
          onChange={e =>
            handleChangeDirection(
              e.target.value !== ""
                ? parseSelectedDirection(e.target.value)
                : null
            )
          }
          onKeyUp={e =>
            handleReactEnterKeyPress(e, () => {
              handleSubmitForm();
            })
          }
        >
          <option value="">Select</option>
          {validDirections.map(direction => (
            <option key={direction} value={direction}>
              {directionNames[direction]!.toUpperCase()}{" "}
              {directionDestinations[direction]!}
            </option>
          ))}
        </select>
      </SelectContainer>
      <label className="schedule-finder__label" htmlFor="sf_origin_select">
        Choose an origin stop
      </label>
      <SelectContainer
        error={state.originError}
        handleClick={handleOriginSelectClick}
        id="sf_origin_select_container"
      >
        <select
          id="sf_origin_select"
          className="c-select-custom c-select-custom--noclick"
          value={state.selectedOrigin || ""}
          onChange={e =>
            handleChangeOrigin(e.target.value ? e.target.value : null, false)
          }
          onKeyUp={e =>
            handleReactEnterKeyPress(e, () => {
              handleSubmitForm();
            })
          }
        >
          <option value="">Select</option>
          {stopListOrder(stops, state.selectedDirection, directionId).map(
            ({ id, name }: SimpleStop) => (
              <option key={id} value={id}>
                {name}
              </option>
            )
          )}
        </select>
      </SelectContainer>
      <Modal
        openState={state.modalOpen}
        focusElementId={
          state.modalId === "origin" ? "origin-filter" : "modal-close"
        }
        ariaLabel={{
          label:
            state.modalId === "origin"
              ? "Choose Origin Stop"
              : "Choose Schedule"
        }}
        className={
          state.modalId === "origin" ? "schedule-finder__origin-modal" : ""
        }
        closeModal={() => {
          setState({
            ...state,
            modalOpen: false,
            modalId: null
          });
        }}
      >
        {() => (
          <>
            {state.modalId === "origin" && (
              <OriginModalContent
                selectedDirection={state.selectedDirection}
                selectedOrigin={state.selectedOrigin}
                originSearch={state.originSearch}
                stops={stops[state.selectedDirection!] || []}
                handleChangeOrigin={handleChangeOrigin}
                handleUpdateOriginSearch={handleUpdateOriginSearch}
                directionId={directionId}
              />
            )}
            {state.modalId === "schedule" && (
              <ScheduleModalContent
                route={route}
                selectedDirection={state.selectedDirection}
                selectedOrigin={state.selectedOrigin}
                services={services}
                stops={stops[state.selectedDirection!]}
                routePatternsByDirection={routePatternsByDirection}
                today={today}
                scheduleNote={scheduleNote}
              />
            )}
          </>
        )}
      </Modal>

      <div className="text-right">
        <input
          className="btn btn-primary"
          type="submit"
          value="Get schedules"
          onClick={handleSubmitForm}
        />
      </div>
    </div>
  );
};

export default ScheduleFinder;
