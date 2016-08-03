(function() {
  this.BlobLicenseSelectors = (function() {
    function BlobLicenseSelectors(opts) {
      var ref;
      this.$dropdowns = (ref = opts.$dropdowns) != null ? ref : $('.js-license-selector'), this.editor = opts.editor;
      this.$dropdowns.each((function(_this) {
        return function(i, dropdown) {
          var $dropdown;
          $dropdown = $(dropdown);
          return new BlobLicenseSelector({
            pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
            data: $dropdown.data('data'),
            wrapper: $dropdown.closest('.js-license-selector-wrap'),
            dropdown: $dropdown,
            editor: _this.editor
          });
        };
      })(this));
    }

    return BlobLicenseSelectors;

  })();

}).call(this);
