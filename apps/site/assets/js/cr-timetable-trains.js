import {
  CRTimetableTrainIcons,
  removeTrain,
  allTrainsClass
} from "./cr-timetable-train-icons";

/* eslint-disable class-methods-use-this */
export const channelDataId = "js-cr-vehicle-data";
const vehicleScheduleDataId = "js-cr-vehicle-schedules-data";
const vehicleStopSequenceDataId = "js-cr-vehicle-prior-stops-data";

export class CRTimetableTrains {
  constructor(dataEl) {
    this.data = {};
    try {
      this.getData();
    } catch (e) {
      throw new Error(
        "Not able to parse initial data from Commuter Rail Timetable",
        e.message
      );
    }
    this.bind();
    this.channelId = dataEl.getAttribute("data-channel");
    this.addEventListeners();
    this.icons = new CRTimetableTrainIcons({
      schedules: this.schedules,
      priorStops: this.priorStops
    });
  }

  getData() {
    const schedules = document.getElementById(vehicleScheduleDataId);
    this.data.schedulesInfo = JSON.parse(schedules.textContent);
    const priorStops = document.getElementById(vehicleStopSequenceDataId);
    this.data.stopMap = JSON.parse(priorStops.textContent);
  }

  get schedules() {
    return this.data.schedulesInfo;
  }

  set schedules(sched) {
    this.data.schedulesInfo = sched;
  }

  get priorStops() {
    return this.data.stopMap;
  }

  set priorStops(stops) {
    this.data.stopMap = stops;
  }

  bind() {
    this.onVehicles = this.onVehicles.bind(this);
    this.onRemoveVehicles = this.onRemoveVehicles.bind(this);
  }

  addEventListeners() {
    window.$(document).on(this.channelId, this.onVehicles);
    window.$(document).on("vehicles:remove", this.onRemoveVehicles);
    document.addEventListener(
      "turbolinks:before-render",
      this.teardown.bind(this),
      {
        passive: true
      }
    );
  }

  removeEventListeners() {
    window.$(document).off(this.channelId, this.onVehicles);
    window.$(document).off("vehicles:remove", this.onRemoveVehicles);
  }

  onVehicles(ev, { data }) {
    // eslint-disable-next-line no-shadow
    data.forEach(vehicle => this.icons.addOrUpdateTrain(vehicle));
  }

  onRemoveVehicles(ev, { data }) {
    data.forEach(d => removeTrain(d.toString().split("-")[1]));
  }

  teardown() {
    this.removeEventListeners();
  }
}

export default function() {
  document.addEventListener(
    "turbolinks:load",
    () => {
      const dataEls = document.getElementById(channelDataId);
      if (dataEls) {
        return new CRTimetableTrains(dataEls);
      }
      return {};
    },
    { passive: true }
  );
}
