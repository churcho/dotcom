import { assert } from "chai";
import jsdom from "mocha-jsdom";
import { geolocationCallback, getFriendlyTime, default as tripPlan } from "../../assets/js/trip-plan";

describe("trip-plan", () => {
  var $;
  jsdom();

  beforeEach( () => {
    $ = jsdom.rerequire("jquery");

    $("body").append(`
      <input class="location-input" data-autocomplete="true" id="from" name="plan[from]" placeholder="Ex: 10 Park Plaza" type="text" autocomplete="off">
      <input type="hidden" id="plan_from_latitude" name="plan[from_latitude]">
      <input type="hidden" id="plan_from_longitude" name="plan[from_longitude]">
      <input class="location-input" data-autocomplete="true" id="to" name="plan[to]" placeholder="Ex: Boston Children's Museum" type="text" autocomplete="off">
      <input type="hidden" id="plan_to_latitude" name="plan[to_latitude]">
      <input type="hidden" id="plan_to_longitude" name="plan[to_longitude]">
    `);
    tripPlan($);
  });

  describe("fills the form with the lat/lng", () => {
    it("sets the value attribute of the related hidden input fields", () => {
      const fromEvent = { target: document.getElementById("from") };
      const fromLocation = { coords: { latitude: 42.3428, longitude: -71.0857 } };

      geolocationCallback($)(fromEvent, fromLocation);

      assert.equal($("#plan_from_latitude").val(), String(fromLocation.coords.latitude));
      assert.equal($("#plan_from_longitude").val(), String(fromLocation.coords.longitude));
      assert.equal($("#plan_to_latitude").val(), "");
      assert.equal($("#plan_to_longitude").val(), "");


      const toEvent = { target: document.getElementById("to") };
      const toLocation = { coords: { latitude: 42.3467, longitude: -71.0972 } };

      geolocationCallback($)(toEvent, toLocation);

      assert.equal($("#plan_from_latitude").val(), String(fromLocation.coords.latitude));
      assert.equal($("#plan_from_longitude").val(), String(fromLocation.coords.longitude));
      assert.equal($("#plan_to_latitude").val(), String(toLocation.coords.latitude));
      assert.equal($("#plan_to_longitude").val(), String(toLocation.coords.longitude));
    });

    it("sets the value of the text box to 'Your current location', and sets the .trip-plan-current-location class", () => {
      const fromEvent = { target: document.getElementById("from") };
      const fromLocation = { coords: { latitude: 42.3428, longitude: -71.0857 } };

      geolocationCallback($)(fromEvent, fromLocation);

      assert.equal($("#from").val(), "Your current location");
      assert.isTrue($("#from").hasClass("trip-plan-current-location"));
    });

    it("removes the .trip-plan-current-location class when the user makes a change", () => {
      const $to = $("#to");
      $to.val("Your current location");
      $to.addClass("trip-plan-current-location");
      $("#plan_to_latitude").val("42.3428");
      $("#plan_from_latitude").val("-71.0857");

      $to.val("Boston Symphony Hall");
      $to.trigger("input");

      assert.isFalse($("#to").hasClass("trip-plan-current-location"));
      assert.equal($("#to").val(), "");
      assert.equal($("#plan_to_latitude").val(), "");
      assert.equal($("#plan_to_longitude").val(), "");
    });

    it("does not delete the first letter when user deletes the current location as they start typing", () => {
      const $to = $("#to");
      $to.val("Your current location");
      $to.addClass("trip-plan-current-location");
      $("#plan_to_latitude").val("42.3428");
      $("#plan_from_latitude").val("-71.0857");

      $to.val("x");
      $to.trigger("input");

      assert.isFalse($("#to").hasClass("trip-plan-current-location"));
      assert.equal($("#to").val(), "x");
      assert.equal($("#plan_to_latitude").val(), "");
      assert.equal($("#plan_to_longitude").val(), "");
    });
  });

  describe("getFriendlyTime", () => {
    it("returns a friendly string given a JavaScript date", () => {
      const date = new Date(2017, 10, 9, 8, 7);

      assert.equal(getFriendlyTime(date), "8:07 AM")
    });

    it("converts times after 13:00 to PM", () => {
      const date = new Date(2017, 10, 9, 18, 19);

      assert.equal(getFriendlyTime(date), "6:19 PM")
    });

    it("interprets 12:00 as 12:00 PM", () => {
      const date = new Date(2017, 10, 9, 12, 7);

      assert.equal(getFriendlyTime(date), "12:07 PM")
    });

    it("interprets 0:00 as 12:00 AM", () => {
      const date = new Date(2017, 10, 9, 0, 7);

      assert.equal(getFriendlyTime(date), "12:07 AM")
    });
  });
});
