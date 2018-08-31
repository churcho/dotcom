import { doWhenGoogleMapsIsReady } from "./google-maps-loaded";
import { Algolia } from "./algolia-search";
import * as AlgoliaResult from "./algolia-result";
import { AlgoliaAutocompleteWithGeo } from "./algolia-autocomplete-with-geo";
import * as QueryStringHelpers from "./query-string-helpers";

import { PAGE_IDS, FACET_MAP, buildOptions } from "./algolia-embedded-search-options";

export class AlgoliaEmbeddedSearch {
  constructor({ pageId, selectors, params, indices, locationParams }) {
    this.pageId = pageId;
    this.selectors = selectors;
    this.params = params;
    this.indices = indices;
    this.locationParams = locationParams || { position: Object.keys(indices).length, hitLimit: 3 }
    this.input = document.getElementById(selectors.input);
    this.controller = null;
    this.autocomplete = null;
    this.goBtn = document.getElementById(selectors.goBtn);
    this.bind();
    if (this.input) {
      this.init();
    }
  }

  bind() {
    this.onClickGoBtn = this.onClickGoBtn.bind(this);
  }

  init() {
    this.input.value = "";
    this.controller = new Algolia(this.indices, this.params);
    this.autocomplete = new AlgoliaAutocompleteWithGeo(
      this.pageId,
      this.selectors,
      Object.keys(this.indices),
      this.locationParams,
      this
    );
    this.autocomplete.renderFooterTemplate =
      AlgoliaEmbeddedSearch.renderFooterTemplate;
    this.addEventListeners();
    this.controller.addWidget(this.autocomplete);
  }

  addEventListeners() {
    this.goBtn.removeEventListener("click", this.onClickGoBtn);
    this.goBtn.addEventListener("click", this.onClickGoBtn);
  }

  buildSearchParams() {
    return QueryStringHelpers.parseParams({
      query: this.input.value,
      facets: this.facets(),
      showmore: this.indexNames()
    });
  }

  onClickGoBtn() {
    return window.Turbolinks.visit(`/search${this.buildSearchParams()}`);
  }

  indexNames() {
    return Object.keys(this.indices).join(",");
  }

  facets() {
    return FACET_MAP[this.pageId];
  }

  getParams() {
    return {
      from: this.pageId,
      query: this.input.value
    };
  }

  static renderFooterTemplate(indexName) {
    if (indexName === "locations") {
      return AlgoliaResult.TEMPLATES.poweredByGoogleLogo.render({
        logo: document.getElementById("powered-by-google-logo").innerHTML
      });
    }
    return null;
  }
}

export function init() {
  PAGE_IDS.forEach(pageId => {
    const { selectors, params, indices } = buildOptions(pageId);

    document.addEventListener("turbolinks:load", () => {
      doWhenGoogleMapsIsReady(
        () => new AlgoliaEmbeddedSearch({ pageId, selectors, params, indices })
      );
    });
  });
}
