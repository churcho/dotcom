import { expect } from "chai";
import sinon from "sinon";
import jsdom from "mocha-jsdom";
import { Algolia } from "../../assets/js/algolia-search";
import { AlgoliaGlobalSearch } from "../../assets/js/algolia-global-search";

describe("AlgoliaGlobalSearch", function() {
  jsdom({
    scripts: [
      'https://maps.googleapis.com/maps/api/js?libraries=places,geometry',
    ],
  });

  beforeEach(function() {
    window.algoliaConfig = {
      app_id: process.env.ALGOLIA_APP_ID,
      search: process.env.ALGOLIA_SEARCH_KEY,
      places: {
        app_id: process.env.ALGOLIA_PLACES_APP_ID,
        search: process.env.ALGOLIA_PLACES_SEARCH_KEY
      }
    }
    window.jQuery = jsdom.rerequire("jquery");
    document.body.innerHTML = "";
    Object.keys(AlgoliaGlobalSearch.SELECTORS).forEach(key => {
      document.body.innerHTML += `<div id="${AlgoliaGlobalSearch.SELECTORS[key]}"></div>`;
    });
    document.body.innerHTML += `<div id="powered-by-google-logo"></div>`;

  });

  it("constructor does not create a new Algolia instance", function() {
    const globalSearch = new AlgoliaGlobalSearch()
    expect(globalSearch.controller).to.equal(null);
  });

  describe("init", function() {
    it("generates a new Algolia client if search element exists", function() {
      const globalSearch = new AlgoliaGlobalSearch();
      expect(document.getElementById(AlgoliaGlobalSearch.SELECTORS.searchBar)).to.be.an.instanceOf(window.HTMLDivElement);
      globalSearch.init();
      expect(globalSearch.controller).to.be.an.instanceOf(Algolia);
    });

    it("does not generates a new Algolia client if search element does not exist", function() {
      document.body.innerHTML = "";
      const globalSearch = new AlgoliaGlobalSearch();
      expect(document.getElementById(AlgoliaGlobalSearch.SELECTORS.searchBar)).to.equal(null);
      globalSearch.init();
      expect(globalSearch.controller).to.equal(null);
    });
  });

  describe("loadState", function() {
    it("loads query from query", function() {
      const globalSearch = new AlgoliaGlobalSearch();
      globalSearch.init();
      globalSearch.loadState("?query=foobar");
      expect(globalSearch.container.value).to.equal("foobar");
    });
    it("loads facet state from query", function() {
      document.body.innerHTML += `<div id="search-facets"></div>`;
      window.history.replaceState = sinon.spy();
      const globalSearch = new AlgoliaGlobalSearch();
      globalSearch.init();
      globalSearch.loadState("?query=foobar&facets=lines-routes,locations");
      expect(globalSearch._facetsWidget.selectedFacetNames()).to.have.members(["lines-routes", "locations", "subway", "bus", "commuter-rail", "ferry"]);
    });
  });

  describe("updateHistory", function() {
    it("updates history when query changes", function() {
      document.body.innerHTML += `<div id="search-facets"></div>`;
      window.history.replaceState = sinon.spy();
      const globalSearch = new AlgoliaGlobalSearch();
      globalSearch.init();
      globalSearch.container.value = "foo";
      globalSearch.onInput(null);
      expect(window.history.replaceState.called).to.be.true;
      expect(window.history.replaceState.args[0][2]).to.contain("query=foo");
    });
    it("updates history when facets change", function() {
      document.body.innerHTML += `<div id="search-facets"></div>`;
      window.history.replaceState = sinon.spy();
      const globalSearch = new AlgoliaGlobalSearch();
      globalSearch.init();
      window.jQuery("#checkbox-container-lines-routes").trigger("click");
      expect(window.history.replaceState.called).to.be.true;
      expect(window.history.replaceState.args[0][2]).to.contain("facets=lines-routes,subway,bus,commuter-rail,ferry");
    });
    it("updates history when show more is clicked", function() {
      document.body.innerHTML += `<div id="search-facets"></div>`;
      window.history.replaceState = sinon.spy();
      const globalSearch = new AlgoliaGlobalSearch();
      globalSearch.init();
      globalSearch.onClickShowMore("stops");
      expect(window.history.replaceState.called).to.be.true;
      expect(window.history.replaceState.args[0][2]).to.contain("showmore=stops");
    });
  });

  describe("getParams", function() {
    beforeEach(function() {
      document.body.innerHTML = "";
      Object.keys(AlgoliaGlobalSearch.SELECTORS).forEach(key => {
        const elType = (key == "searchBar") ? "input" : "div"
        document.body.innerHTML += `<${elType} id="${AlgoliaGlobalSearch.SELECTORS[key]}"></${elType}>`;
      });
      document.body.innerHTML += `<div id="powered-by-google-logo"></div>`
      this.globalSearch = new AlgoliaGlobalSearch();
      this.globalSearch.init();
    });

    it("returns an object with from, query, and facet params", function() {
      const params = this.globalSearch.getParams();
      expect(params).to.be.an("object");
      expect(params).to.have.keys(["from", "query", "facets"]);
      expect(params.from).to.equal("global-search");
      expect(params.query).to.equal("");
      expect(params.facets).to.equal("");
    });

    it("query is the value in the search input", function() {
      window.jQuery(`#${AlgoliaGlobalSearch.SELECTORS.searchBar}`).val("new value");
      const params = this.globalSearch.getParams();
      expect(params.query).to.equal("new value");
    });
  });
});
