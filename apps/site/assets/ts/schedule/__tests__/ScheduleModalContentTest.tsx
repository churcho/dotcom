import React from "react";
import { mount } from "enzyme";
import { EnhancedRoute } from "../../__v3api";
import ScheduleModalContent, {
  fetchData
} from "../components/schedule-finder/ScheduleModalContent";
import { SimpleStop } from "../components/__schedule";
import { EnhancedJourney } from "../components/__trips";
import departuresResponse from "../__tests__/departures.json";
import ScheduleNote from "../components/ScheduleNote";
import { ModalProvider } from "./../components/schedule-finder/ModalContext";

const today = "2019-12-05";
const route: EnhancedRoute = {
  alert_count: 0,
  description: "",
  direction_destinations: { 0: "Oak Grove", 1: "Forest Hills" },
  direction_names: { 0: "Inbound", 1: "Outbound" },
  header: "",
  id: "Orange",
  name: "Orange",
  long_name: "Orange Line",
  type: 1
};

const greenRoute: EnhancedRoute = {
  alert_count: 0,
  description: "",
  direction_destinations: { 0: "East", 1: "West" },
  direction_names: { 0: "East", 1: "West" },
  header: "",
  id: "Green",
  name: "Green",
  long_name: "Green Line",
  type: 0
};

const oneDirectionRoute: EnhancedRoute = {
  alert_count: 0,
  description: "",
  direction_destinations: { 0: "Oak Grove", 1: null },
  direction_names: { 0: "Inbound", 1: null },
  header: "",
  id: "Orange",
  name: "Orange",
  long_name: "Orange Line",
  type: 1
};

const scheduleNoteData = {
  offpeak_service: "8-12 minutes",
  peak_service: "5 minutes",
  exceptions: [
    { service: "26 minutes", type: "weekend mornings and late night" }
  ],
  alternate_text: null
};

const stops: SimpleStop[] = [
  { name: "Malden Center", id: "place-mlmnl", is_closed: false, zone: "1" },
  { name: "Wellington", id: "place-welln", is_closed: false, zone: "2" }
];

const payload: EnhancedJourney[] = departuresResponse as EnhancedJourney[];

describe("ScheduleModalContent", () => {
  it("renders", () => {
    const wrapper = mount(
      <ScheduleModalContent
        route={route}
        stops={{ 0: stops, 1: stops }}
        services={[]}
        routePatternsByDirection={{}}
        today={today}
        scheduleNote={null}
      />,
      {
        wrappingComponent: ModalProvider,
        wrappingComponentProps: {
          modalId: "test",
          selectedDirection: 0,
          selectedOrigin: stops[0].id
        }
      }
    );

    expect(wrapper.debug()).toMatchSnapshot();
  });

  it("renders with a unique destination name for the Green route", () => {
    const wrapper = mount(
      <ScheduleModalContent
        route={greenRoute}
        stops={{ 0: stops, 1: stops }}
        services={[]}
        routePatternsByDirection={{}}
        today={today}
        scheduleNote={null}
      />,
      {
        wrappingComponent: ModalProvider,
        wrappingComponentProps: {
          modalId: "test",
          selectedDirection: 0,
          selectedOrigin: stops[0].id
        }
      }
    );

    expect(wrapper.debug()).toMatchSnapshot();
  });

  it("renders with schedule note if present", () => {
    const wrapper = mount(
      <ScheduleModalContent
        route={route}
        stops={{ 0: stops, 1: stops }}
        services={[]}
        routePatternsByDirection={{}}
        today={today}
        scheduleNote={scheduleNoteData}
      />,
      {
        wrappingComponent: ModalProvider,
        wrappingComponentProps: {
          modalId: "test",
          selectedDirection: 0,
          selectedOrigin: stops[0].id
        }
      }
    );

    expect(wrapper.debug()).toMatchSnapshot();
    expect(wrapper.find(ScheduleNote).text()).toContain("8-12 minutes");
  });

  describe("fetchData", () => {
    it("fetches data", () => {
      const spy = jest.fn();
      window.fetch = jest.fn().mockImplementation(
        () =>
          new Promise((resolve: Function) =>
            resolve({
              json: () => payload,
              ok: true,
              status: 200,
              statusText: "OK"
            })
          )
      );

      return fetchData("1", "99", 0, spy).then(() => {
        expect(window.fetch).toHaveBeenCalledWith(
          "/schedules/finder_api/departures?id=1&stop=99&direction=0"
        );
        expect(spy).toHaveBeenCalledWith({
          type: "FETCH_STARTED"
        });
        expect(spy).toHaveBeenCalledWith({
          type: "FETCH_COMPLETE",
          payload
        });
      });
    });

    it("fails gracefully if fetch is unsuccessful", () => {
      const spy = jest.fn();
      window.fetch = jest.fn().mockImplementation(
        () =>
          new Promise((resolve: Function) =>
            resolve({
              json: () => "Internal Server Error",
              ok: false,
              status: 500,
              statusText: "INTERNAL SERVER ERROR"
            })
          )
      );

      return fetchData(route.id, stops[0].id, 0, spy).then(() => {
        expect(window.fetch).toHaveBeenCalledWith(
          "/schedules/finder_api/departures?id=Orange&stop=place-mlmnl&direction=0"
        );
        expect(spy).toHaveBeenCalledWith({
          type: "FETCH_STARTED"
        });
        expect(spy).toHaveBeenCalledWith({
          type: "FETCH_ERROR"
        });
      });
    });
  });
});
