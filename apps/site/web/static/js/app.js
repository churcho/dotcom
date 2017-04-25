// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

window.$ = window.jQuery;

window.requestIdleCallback = window.requestIdleCallback ||
  function (cb) {
    return window.setTimeout(function () {
      var start = Date.now();
      cb({
        didTimeout: false,
        timeRemaining: function () {
          return Math.max(0, 50 - (Date.now() - start));
        }
      });
    }, 1);
  };


import submitOnEvents from './submit-on-events.js';
import selectModal from './select-modal.js';
import tooltip from './tooltip.js';
import collapse from './collapse.js';
import modal from './modal.js';
import turbolinks from './turbolinks';
import supportForm from './support-form.js';
import objectFitImages from 'object-fit-images';
import fixedsticky from './fixedsticky';
import horizsticky from './horizsticky';
import menuCtrlClick from './menu-ctrl-click';
import carousel from './carousel';
import geoLocation from './geolocation';
import transitNearMe from './transit-near-me';
import googleMap from './google-map';
import scrollTo from './scroll-to';
import stickyTooltip from './sticky-tooltip';
import timetableScroll from './timetable-scroll';
import menuClose from './menu-close';
import datePicker from './date-picker';

submitOnEvents(["blur", "change"]);
selectModal();
tooltip();
collapse();
modal();
turbolinks();
supportForm();
fixedsticky();
horizsticky();
objectFitImages(); // Polyfill for IE object-fit support
menuCtrlClick();
carousel();
geoLocation();
transitNearMe();
googleMap();
scrollTo();
stickyTooltip();
timetableScroll();
menuClose();
datePicker();

$("body").removeClass("no-js").addClass("js");
