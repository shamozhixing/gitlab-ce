
/*= require blob/template_selector */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.BlobCiYamlSelector = (function(superClass) {
    extend(BlobCiYamlSelector, superClass);

    function BlobCiYamlSelector() {
      return BlobCiYamlSelector.__super__.constructor.apply(this, arguments);
    }

    BlobCiYamlSelector.prototype.requestFile = function(query) {
      return Api.gitlabCiYml(query.name, this.requestFileSuccess.bind(this));
    };

    return BlobCiYamlSelector;

  })(TemplateSelector);

  this.BlobCiYamlSelectors = (function() {
    function BlobCiYamlSelectors(opts) {
      var ref;
      this.$dropdowns = (ref = opts.$dropdowns) != null ? ref : $('.js-gitlab-ci-yml-selector'), this.editor = opts.editor;
      this.$dropdowns.each((function(_this) {
        return function(i, dropdown) {
          var $dropdown;
          $dropdown = $(dropdown);
          return new BlobCiYamlSelector({
            pattern: /(.gitlab-ci.yml)/,
            data: $dropdown.data('data'),
            wrapper: $dropdown.closest('.js-gitlab-ci-yml-selector-wrap'),
            dropdown: $dropdown,
            editor: _this.editor
          });
        };
      })(this));
    }

    return BlobCiYamlSelectors;

  })();

}).call(this);
