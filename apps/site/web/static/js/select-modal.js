import Sifter from 'sifter';

export default function($ = window.jQuery) {
  convertSelects($);

  // create the modal when we click on the fake select
  $(document).on("click openModal", "[data-select-modal]",
                 (ev) => openModal(ev, $));

  $(document).on('keyup', '.select-modal-search input',
                 (ev) => searchChanged(ev, $));

  $(document).on('submit', '.select-modal',
                 (ev) => searchSubmitted(ev, $));

  $(document).on("click", ".select-modal .select-modal-option",
                 (ev) => optionSelected(ev, $));

  $(document).on('shown.bs.modal', '.select-modal',
                 (ev) => modalShown(ev, $));

  $(document).on("hidden.bs.modal", ".select-modal",
                 (ev) => modalHidden(ev, $));

  $(document).on("click", "[data-select-modal-open]",
                 (ev) => openRemoteModal(ev, $));

  $(document).on("turbolinks:load", () => convertSelects($));
}

function openModal(ev, $) {
  ev.preventDefault();
  ev.stopPropagation();
  const $target = $(ev.currentTarget); // the button we clicked
  const $select = $target.data('select-modal-select'); // the <select>
  const selectData = dataFromSelect($select, $);
  const options = optionsFromSelect($select, $);
  const $modal = $newModal($select.attr('name'), $);
  renderModal($modal, selectData, options);
  $modal
    .data('select-modal-select', $select)
    .modal({
      keyboard: true,
      show: true
    });
  return false;
}

function openRemoteModal(ev, $) {
  ev.preventDefault();
  ev.stopPropagation();
  const name = $(ev.currentTarget).data('select-modal-open');
  $(`[data-select-modal=${name}]`).trigger('openModal');
  return false;
}

function searchChanged(ev, $) {
  const $target = $(ev.currentTarget);
  const $modal = $target.parents('.select-modal');
  const data = $modal.data('select-modal-data');
  const sifter = $modal.data('select-modal-sifter');

  // filter the data and re-render those options
  const newData = filterData(data, $target.val(), sifter);
  $modal.find('.select-modal-options').html(
    newData.map(renderOption).join('')
  );
}

function searchSubmitted(ev, $) {
  // find the first non-disabled button and click it
  ev.preventDefault();
  ev.stopPropagation();
  $(ev.currentTarget).find('.select-modal-option:first-child:not(.select-modal-option-disabled)').click();
}

function optionSelected(ev, $) {
  // update the original select and the fake select when we click on an option
  ev.preventDefault();
  ev.stopPropagation();

  const $target = $(ev.currentTarget),
  $parent = $target.parents(".select-modal"),
  value = $target.data('value');

  $parent.data('select-modal-select').siblings('.select-modal-text').text($target.text());
  $parent.data('select-modal-select').val(value).change();
  $parent.modal('hide');
  return false;
}

function modalShown(ev, $) {
  if (!/iPad|iPhone|Android/.exec(navigator.userAgent)) {
    // focus search when the modal is open (desktop)
    $(ev.currentTarget).find('.select-modal-search label').focus();
  }
}

function modalHidden(ev, $) {
  // remove the generated modal once it's closed
  $(ev.currentTarget).remove();
}

// public so that it can be re-run separately from the global event handlers
export function convertSelects($) {
  $("select[data-select-modal]").each((_index, el) => {
    // creates a text container (based on the select value) and a button
    // (based on the text of the submit button for the form).
    const $el = $(el),
          $replacementText = $(`<span/>`)
          .addClass('select-modal-text')
          .text(el.options[el.selectedIndex].text),
          $replacement = $(`<button data-select-modal="${$el.attr('name')}" type=button />`)
          .addClass('btn-select-modal')
          .text(buttonText($el.parents("form").find("[type=submit]").text()))
          .data('select-modal-select', $el);
    $el.hide()
      .removeAttr('data-select-modal')
      .after($replacementText)
      .parents("form")
      .find("[type=submit]")
      .after($replacement);
  });
}

function buttonText(text) {
  // The buttons have text like 'Change Departure', but we want the text to
  // be lower case and be wrapped in parens: '(change departure)'
  return `(${text.toLowerCase()})`;
}

export function dataFromSelect($el, $) {
  return $el
    .children('option')
    .map(dataFromOption($))
    .get()
    .filter(({value: value}) => value !== "");
}

export function optionsFromSelect($el, $) {
  return {
    label: $(`label[for=${$el.attr('id')}]`).html()
  };
}

export function $newModal(id, $) {
  const modalId = id + 'Modal';
  const $existing = $('#' + modalId);
  if ($existing.length > 0) {
    return $existing;
  }

  const $div = $(`<div
class='modal select-modal'
id='${modalId}'
tabindex="-1"
role="dialog"
data-original-id='#${id}'>
</div>`);
  $('body').append($div);
  return $div;
}

export function renderModal($modal, data, options) {
  $modal.html(`
<div class='modal-dialog role='document'>
  <div class="modal-content">
    <div class="modal-body">
      ${renderCloseButton()}
      <form class="select-modal-search">
        ${renderSearch(data, options)}
      </form>
      <div class="select-modal-options list-group list-group-flush">
        ${data.map(renderOption).join('')}
      </div>
    </div>
  </div>
</div>
`)
    .data('select-modal-data', data)
    .data('select-modal-sifter', new Sifter(data));
}

function renderCloseButton() {
  return `
<button type="button" class="close btn btn-link pull-right p-t-0" data-dismiss="modal" aria-label="Close">
  <i class="fa fa-close" aria-hidden="true"/> Close
</button>`;
}


function dataFromOption($) {
  return (_index, option) => {
    const $option = $(option);
    const data = {
      name: $option.text().replace(/\(.+\)/, '').trim(),
      html: $option.html(),
      value: $option.val()
    };
    if ($option.attr('selected')) {
      data.selected = true;
    }
    if ($option.attr('disabled')) {
      data.disabled = true;
    }
    return data;
  };
}

function renderSearch(data, options) {
  const placeholder = data.find((opt) => !opt.disabled).name;
  return `
<label for="select-modal-search" class="select-modal-label">${options.label}</label>
<input id="select-modal-search" name="select-modal-search" class="form-control" type="search" autocomplete="off" placeholder="Ex ${placeholder}"/>
`;
}

function renderOption(option) {
  const className = [
    'select-modal-option',
    'list-group-item',
    'list-group-item-flush',
    option.selected ? 'selected' : '',
    option.disabled ? 'disabled' : ''
  ].join(' ');
  return `
<button class='${className}' data-value='${option.value}' ${option.disabled ? 'disabled' : ''}>
  <div class='select-modal-option-name'>
    ${option.selected ? '<span class="fa fa-check-circle" aria-hidden=true/>': ''}
    ${option.html}
  </div>
</button>
`;
}

export function filterData(data, query, sifter) {
  if (typeof sifter === 'undefined') {
    sifter = new Sifter(data);
  }
  const search = sifter.search(query, {
    fields: ['name'],
  });

  // sort the items by ID
  search.items.sort((first, second) => first.id - second.id);

  return search.items.map(({id: id}) => data[id]);
}
