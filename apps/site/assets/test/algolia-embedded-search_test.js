import jsdom from "mocha-jsdom";
import sinon from "sinon";
import { expect } from "chai";
import { Algolia } from "../js/algolia-search";
import { AlgoliaEmbeddedSearch } from "../js/algolia-embedded-search";
import { AlgoliaAutocomplete } from "../js/algolia-autocomplete";
import { PAGE_IDS, buildOptions } from "../js/algolia-embedded-search-options";

function setup(idx) {
  const id = PAGE_IDS[idx];
  const {
    selectors,
    indices,
    params
  } = buildOptions(id);
  document.body.innerHTML = `
    <div id="powered-by-google-logo"></div>
    <input id="${selectors.input}"></input>
    <div id="${selectors.resetButton}"></div>
    <button id ="${selectors.goBtn}"></button>
  `;

  return new AlgoliaEmbeddedSearch({
    pageId: id,
    selectors,
    params,
    indices
  })
}

describe("AlgoliaEmbeddedSearch", () => {
  jsdom();
  beforeEach(() => {
    window.jQuery = jsdom.rerequire("jquery");
    window.autocomplete = jsdom.rerequire("autocomplete.js");
    window.encodeURIComponent = (str) => str;
    window.Turbolinks = {
      visit: sinon.spy()
    }
  });

  describe("constructor", () => {
    it("initializes autocomplete if input exists", () => {

      const pageId = PAGE_IDS[0];
      const {
        selectors,
        params,
        indices
      } = buildOptions(pageId);
      const ac = setup(0);
      expect(ac.input).to.be.an.instanceOf(window.HTMLInputElement);
      expect(ac.controller).to.be.an.instanceOf(Algolia);
      expect(ac.autocomplete).to.be.an.instanceOf(AlgoliaAutocomplete);
      expect(ac.controller.widgets).to.include(ac.autocomplete);
    });
    it("does not initialize autocomplete if input does not exist", () => {
      document.body.innerHTML = `
        <input id="stop-search-fail"></input>
      `;
      const pageId = PAGE_IDS[0];
      const {
        selectors,
        indices,
        params
      } = buildOptions(pageId);
      const ac = new AlgoliaEmbeddedSearch({
        selectors,
        params,
        indices,
        pageId
      });

      expect(ac.input).to.equal(null);
      expect(ac.controller).to.equal(null);
      expect(ac.autocomplete).to.equal(null);
    });
  });

  describe("clicking Go button", () => {
    it("calls autocomplete.clickHighlightedOrFirstResult", () => {
      const search = setup(0);
      sinon.spy(search.onClickGoBtn);

      const $ = window.jQuery;

      const $goBtn = $(`#${search.selectors.goBtn}`);
      expect($goBtn.length).to.equal(1);

      $goBtn.click();
      expect(window.Turbolinks.visit.called).to.be.true;
      expect(window.Turbolinks.visit.args[0][0]).to.equal("/search?query=&facets=stations,stops&showmore=stops");
    });
  });

  describe("showLocation", () => {
    it("adds query parameters for analytics", () => {
      const ac = setup(0);

      window.encodeURIComponent = string => string.replace(/\s/g, "%20").replace(/\&/g, "%26");
      ac.autocomplete.showLocation("42.0", "-71.0", "10 Park Plaza, Boston, MA");
      expect(window.Turbolinks.visit.called).to.be.true;
      expect(window.Turbolinks.visit.args[0][0]).to.contain("from=search-stop");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("latitude=42.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("longitude=-71.0");
      expect(window.Turbolinks.visit.args[0][0]).to.contain("address=10%20Park%20Plaza,%20Boston,%20MA");
    });
  });

  describe("buildSearchParams", () => {
    it("builds a string of query params", () => {
      expect(PAGE_IDS).to.have.a.lengthOf(6)
      const stopSearch = setup(0);
      expect(stopSearch.pageId).to.equal("search-stop");
      expect(stopSearch.buildSearchParams()).to.equal("?query=&facets=stations,stops&showmore=stops")

      const routeSearch = setup(1);
      expect(routeSearch.pageId).to.equal("search-route");
      expect(routeSearch.buildSearchParams()).to.equal("?query=&facets=subway,commuter-rail,bus,ferry&showmore=routes")

      const subwaySearch = setup(2);
      expect(subwaySearch.pageId).to.equal("search-route--subway");
      expect(subwaySearch.buildSearchParams()).to.equal("?query=&facets=subway&showmore=routes");

      const crSearch = setup(3);
      expect(crSearch.pageId).to.equal("search-route--commuter_rail");
      expect(crSearch.buildSearchParams()).to.equal("?query=&facets=commuter-rail&showmore=routes");

      const busSearch = setup(4);
      expect(busSearch.pageId).to.equal("search-route--bus");
      expect(busSearch.buildSearchParams()).to.equal("?query=&facets=bus&showmore=routes");


      const ferrySearch = setup(5);
      expect(ferrySearch.pageId).to.equal("search-route--ferry");
      expect(ferrySearch.buildSearchParams()).to.equal("?query=&facets=ferry&showmore=routes");
    })
  })
});
