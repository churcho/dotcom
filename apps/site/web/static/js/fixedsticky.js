export default function($) {
  $ = $ || window.jQuery;

  function fixedsticky() {
    $(".fixedsticky").fixedsticky('destroy');
    $(".fixedsticky").fixedsticky();
  }
  document.addEventListener('turbolinks:load', () => window.nextTick(fixedsticky));
  document.addEventListener('shown.bs.collapse', () => window.nextTick(fixedsticky));
}
