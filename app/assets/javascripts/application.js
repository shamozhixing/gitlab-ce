/*= require jquery2 */
/*= require jquery-ui/autocomplete */
/*= require jquery-ui/datepicker */
/*= require jquery-ui/draggable */
/*= require jquery-ui/effect-highlight */
/*= require jquery-ui/sortable */
/*= require jquery_ujs */
/*= require jquery.cookie */
/*= require jquery.endless-scroll */
/*= require jquery.highlight */
/*= require jquery.waitforimages */
/*= require jquery.atwho */
/*= require jquery.scrollTo */
/*= require jquery.turbolinks */
/*= require turbolinks */
/*= require autosave */
/*= require bootstrap/affix */
/*= require bootstrap/alert */
/*= require bootstrap/button */
/*= require bootstrap/collapse */
/*= require bootstrap/dropdown */
/*= require bootstrap/modal */
/*= require bootstrap/scrollspy */
/*= require bootstrap/tab */
/*= require bootstrap/transition */
/*= require bootstrap/tooltip */
/*= require bootstrap/popover */
/*= require select2 */
/*= require ace/ace */
/*= require ace/ext-searchbox */
/*= require underscore */
/*= require dropzone */
/*= require mousetrap */
/*= require mousetrap/pause */
/*= require shortcuts */
/*= require shortcuts_navigation */
/*= require shortcuts_dashboard_navigation */
/*= require shortcuts_issuable */
/*= require shortcuts_network */
/*= require jquery.nicescroll */
/*= require date.format */
/*= require_directory ./behaviors */
/*= require_directory ./blob */
/*= require_directory ./commit */
/*= require_directory ./extensions */
/*= require_directory ./lib/utils */
/*= require_directory ./u2f */
/*= require_directory . */
/*= require fuzzaldrin-plus */

(function() {
  window.slugify = function(text) {
    return text.replace(/[^-a-zA-Z0-9]+/g, '_').toLowerCase();
  };

  window.ajaxGet = function(url) {
    return $.ajax({
      type: "GET",
      url: url,
      dataType: "script"
    });
  };

  window.split = function(val) {
    return val.split(/,\s*/);
  };

  window.extractLast = function(term) {
    return split(term).pop();
  };

  window.rstrip = function(val) {
    if (val) {
      return val.replace(/\s+$/, '');
    } else {
      return val;
    }
  };

  window.disableButtonIfEmptyField = function(field_selector, button_selector) {
    var closest_submit, field;
    field = $(field_selector);
    closest_submit = field.closest('form').find(button_selector);
    if (rstrip(field.val()) === "") {
      closest_submit.disable();
    }
    return field.on('input', function() {
      if (rstrip($(this).val()) === "") {
        return closest_submit.disable();
      } else {
        return closest_submit.enable();
      }
    });
  };

  window.disableButtonIfAnyEmptyField = function(form, form_selector, button_selector) {
    var closest_submit, updateButtons;
    closest_submit = form.find(button_selector);
    updateButtons = function() {
      var filled;
      filled = true;
      form.find('input').filter(form_selector).each(function() {
        return filled = rstrip($(this).val()) !== "" || !$(this).attr('required');
      });
      if (filled) {
        return closest_submit.enable();
      } else {
        return closest_submit.disable();
      }
    };
    updateButtons();
    return form.keyup(updateButtons);
  };

  window.sanitize = function(str) {
    return str.replace(/<(?:.|\n)*?>/gm, '');
  };

  window.unbindEvents = function() {
    return $(document).off('scroll');
  };

  window.shiftWindow = function() {
    return scrollBy(0, -100);
  };

  document.addEventListener("page:fetch", unbindEvents);

  window.addEventListener("hashchange", shiftWindow);

  window.onload = function() {
    if (location.hash) {
      return setTimeout(shiftWindow, 100);
    }
  };

  $(function() {
    var $body, $document, $sidebarGutterToggle, $window, bootstrapBreakpoint, checkInitialSidebarSize, fitSidebarForSize, flash;
    $document = $(document);
    $window = $(window);
    $body = $('body');
    gl.utils.preventDisabledButtons();
    bootstrapBreakpoint = bp.getBreakpointSize();
    $(".nav-sidebar").niceScroll({
      cursoropacitymax: '0.4',
      cursorcolor: '#FFF',
      cursorborder: "1px solid #FFF"
    });
    $(".js-select-on-focus").on("focusin", function() {
      return $(this).select().one('mouseup', function(e) {
        return e.preventDefault();
      });
    });
    $('.remove-row').bind('ajax:success', function() {
      return $(this).closest('li').fadeOut();
    });
    $('.js-remove-tr').bind('ajax:before', function() {
      return $(this).hide();
    });
    $('.js-remove-tr').bind('ajax:success', function() {
      return $(this).closest('tr').fadeOut();
    });
    $('select.select2').select2({
      width: 'resolve',
      dropdownAutoWidth: true
    });
    $('.js-select2').bind('select2-close', function() {
      return setTimeout((function() {
        $('.select2-container-active').removeClass('select2-container-active');
        return $(':focus').blur();
      }), 1);
    });
    $body.tooltip({
      selector: '.has-tooltip, [data-toggle="tooltip"]',
      placement: function(_, el) {
        var $el;
        $el = $(el);
        return $el.data('placement') || 'bottom';
      }
    });
    $('.trigger-submit').on('change', function() {
      return $(this).parents('form').submit();
    });
    gl.utils.localTimeAgo($('abbr.timeago, .js-timeago'), true);
    if ((flash = $(".flash-container")).length > 0) {
      flash.click(function() {
        return $(this).fadeOut();
      });
      flash.show();
    }
    $body.on('ajax:complete, ajax:beforeSend, submit', 'form', function(e) {
      var buttons;
      buttons = $('[type="submit"]', this);
      switch (e.type) {
        case 'ajax:beforeSend':
        case 'submit':
          return buttons.disable();
        default:
          return buttons.enable();
      }
    });
    $(document).ajaxError(function(e, xhrObj, xhrSetting, xhrErrorText) {
      var ref;
      if (xhrObj.status === 401) {
        return new Flash('You need to be logged in.', 'alert');
      } else if ((ref = xhrObj.status) === 404 || ref === 500) {
        return new Flash('Something went wrong on our end.', 'alert');
      }
    });
    $('.account-box').hover(function() {
      return $(this).toggleClass('hover');
    });
    $document.on('click', '.diff-content .js-show-suppressed-diff', function() {
      var $container;
      $container = $(this).parent();
      $container.next('table').show();
      return $container.remove();
    });
    $('.navbar-toggle').on('click', function() {
      $('.header-content .title').toggle();
      $('.header-content .header-logo').toggle();
      $('.header-content .navbar-collapse').toggle();
      return $('.navbar-toggle').toggleClass('active');
    });
    $body.on("click", ".js-toggle-diff-comments", function(e) {
      $(this).toggleClass('active');
      $(this).closest(".diff-file").find(".notes_holder").toggle();
      return e.preventDefault();
    });
    $document.off("click", '.js-confirm-danger');
    $document.on("click", '.js-confirm-danger', function(e) {
      var btn, form, text;
      e.preventDefault();
      btn = $(e.target);
      text = btn.data("confirm-danger-message");
      form = btn.closest("form");
      return new ConfirmDangerModal(form, text);
    });
    $document.on('click', 'button', function() {
      return $(this).blur();
    });
    $('input[type="search"]').each(function() {
      var $this;
      $this = $(this);
      $this.attr('value', $this.val());
    });
    $document.off('keyup', 'input[type="search"]').on('keyup', 'input[type="search"]', function(e) {
      var $this;
      $this = $(this);
      return $this.attr('value', $this.val());
    });
    $sidebarGutterToggle = $('.js-sidebar-toggle');
    $document.off('breakpoint:change').on('breakpoint:change', function(e, breakpoint) {
      var $gutterIcon;
      if (breakpoint === 'sm' || breakpoint === 'xs') {
        $gutterIcon = $sidebarGutterToggle.find('i');
        if ($gutterIcon.hasClass('fa-angle-double-right')) {
          return $sidebarGutterToggle.trigger('click');
        }
      }
    });
    fitSidebarForSize = function() {
      var oldBootstrapBreakpoint;
      oldBootstrapBreakpoint = bootstrapBreakpoint;
      bootstrapBreakpoint = bp.getBreakpointSize();
      if (bootstrapBreakpoint !== oldBootstrapBreakpoint) {
        return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
      }
    };
    checkInitialSidebarSize = function() {
      bootstrapBreakpoint = bp.getBreakpointSize();
      if (bootstrapBreakpoint === "xs" || "sm") {
        return $document.trigger('breakpoint:change', [bootstrapBreakpoint]);
      }
    };
    $window.off("resize.app").on("resize.app", function(e) {
      return fitSidebarForSize();
    });
    gl.awardsHandler = new AwardsHandler();
    checkInitialSidebarSize();
    new Aside();
    if ($window.width() < 1024 && $.cookie('pin_nav') === 'true') {
      $.cookie('pin_nav', 'false', {
        path: '/',
        expires: 365 * 10
      });
      $('.page-with-sidebar').toggleClass('page-sidebar-collapsed page-sidebar-expanded').removeClass('page-sidebar-pinned');
      $('.navbar-fixed-top').removeClass('header-pinned-nav');
    }
    return $document.off('click', '.js-nav-pin').on('click', '.js-nav-pin', function(e) {
      var $page, $pinBtn, $tooltip, $topNav, doPinNav, tooltipText;
      e.preventDefault();
      $pinBtn = $(e.currentTarget);
      $page = $('.page-with-sidebar');
      $topNav = $('.navbar-fixed-top');
      $tooltip = $("#" + ($pinBtn.attr('aria-describedby')));
      doPinNav = !$page.is('.page-sidebar-pinned');
      tooltipText = 'Pin navigation';
      $(this).toggleClass('is-active');
      if (doPinNav) {
        $page.addClass('page-sidebar-pinned');
        $topNav.addClass('header-pinned-nav');
      } else {
        $tooltip.remove();
        $page.removeClass('page-sidebar-pinned').toggleClass('page-sidebar-collapsed page-sidebar-expanded');
        $topNav.removeClass('header-pinned-nav').toggleClass('header-collapsed header-expanded');
      }
      $.cookie('pin_nav', doPinNav, {
        path: '/',
        expires: 365 * 10
      });
      if ($.cookie('pin_nav') === 'true' || doPinNav) {
        tooltipText = 'Unpin navigation';
      }
      $tooltip.find('.tooltip-inner').text(tooltipText);
      return $pinBtn.attr('title', tooltipText).tooltip('fixTitle');
    });
  });

}).call(this);
