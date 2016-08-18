(function() {
  (function(w) {
    var base;
    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).utils == null) {
      base.utils = {};
    }
    w.gl.utils.days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    w.gl.utils.formatDate = function(datetime) {
      return dateFormat(datetime, 'mmm d, yyyy h:MMtt Z');
    };

    w.gl.utils.getDayName = function(date) {
      return this.days[date.getDay()];
    };

    w.gl.utils.localTimeAgo = function($timeagoEls, setTimeago) {
      if (setTimeago == null) {
        setTimeago = true;
      }
      $timeagoEls.each(function() {
        var $el;
        $el = $(this);
        return $el.attr('title', gl.utils.formatDate($el.attr('datetime')));
      });
      if (setTimeago) {
        $timeagoEls.timeago();
        $timeagoEls.tooltip('destroy');
        return $timeagoEls.tooltip({
          template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
        });
      }
    };

    w.gl.utils.shortTimeAgo = function($el) {
      var tmpLocale = $.timeago.settings.strings;

      // Set short locale for timeago
      $.timeago.settings.strings = {
        prefixAgo: null,
        prefixFromNow: null,
        suffixAgo: 'ago',
        suffixFromNow: 'from now',
        seconds: '1 min',
        minute: '1 min',
        minutes: '%d mins',
        hour: '1 hr',
        hours: '%d hrs',
        day: '1 day',
        days: '%d days',
        month: '1 month',
        months: '%d months',
        year: '1 year',
        years: '%d years',
        wordSeparator: ' ',
        numbers: []
      };

      $el.each(function() {
        var $el = $(this);
        var elementDatetime = $.trim($el.text());

        // Set short date
        $el.text($.timeago(new Date(elementDatetime)));

        // Set tooltip
        $el.attr('title', gl.utils.formatDate(elementDatetime)); // The tooltip should have the time based on user's timezone
        $el.tooltip();
      });

      // Restore default locale for timeago
      $.timeago.settings.strings = tmpLocale;
    };

  })(window);

}).call(this);
