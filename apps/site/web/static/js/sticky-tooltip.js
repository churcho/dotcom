// Sourced from https://gist.github.com/alekseyg/d2261e42a9b5335a8ce0774b4d92f129 with small
// modifications. Fixes being unable to dismiss tooltips on iOS devices.

export default function ($) {
  $ = $ || window.jQuery;

  const wasTapped = (element) => {
    const touchStart = element.data('lastTouchStart');
    const touchEnd = element.data('lastTouchEnd');
    return (
      touchStart && touchEnd &&
      touchEnd.timeStamp - touchStart.timeStamp <= 500 &&   // duration
      Math.abs(touchEnd.pageX - touchStart.pageX) <= 10 &&  // deltaX
      Math.abs(touchEnd.pageY - touchStart.pageY) <= 10     // deltaY
    );
  };

  const wasTouchedRecently = (element) => {
    const lastTouch = element.data('lastTouchEnd') || element.data('lastTouchStart');
    return lastTouch && new Date() - lastTouch.timeStamp <= 550;
  };

  const hideTooltip = (element) => {
    window.setTimeout(() => {
      element.tooltip('hide');
    }, 10);
  };

  const initTooltip = () => {
    const selector = '[data-toggle="tooltip"]';

    $(document).on('touchstart', selector, function (e) {
      $(this).data('lastTouchStart', e.originalEvent);
    });
    $(document).on('touchend', selector, function (e) {
      e.stopPropagation();
      const $this = $(this);
      $this.data('lastTouchEnd', e.originalEvent);

      if (wasTapped($this)) {
        $this.tooltip('toggle');
      }
    });
    $(document).on('mouseenter', selector, function (e) {
      const $this = $(this);
      if (wasTouchedRecently($this)) {
        return;
      }

      $this.tooltip('show');
    });
    $(document).on('mouseleave', selector, function (e) {
      const $this = $(this);
      if (wasTouchedRecently($this)) {
        return;
      }

      hideTooltip($this);
    });

    $(document).on('touchend', 'body', () => {
      hideTooltip($('[data-toggle="tooltip"]'));
    });
  };

  initTooltip();
  $(document).on('turbolinks:load', () => $('[data-toggle="tooltip"]').tooltip({trigger: 'manual'}));
};
