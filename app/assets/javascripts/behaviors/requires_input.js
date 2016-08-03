
/*= require extensions/jquery */

(function() {
  $.fn.requiresInput = function() {
    var $button, $form, fieldSelector, requireInput, required;
    $form = $(this);
    $button = $('button[type=submit], input[type=submit]', $form);
    required = '[required=required]';
    fieldSelector = "input" + required + ", select" + required + ", textarea" + required;
    requireInput = function() {
      var values;
      values = _.map($(fieldSelector, $form), function(field) {
        return field.value;
      });
      if (values.length && _.any(values, _.isEmpty)) {
        return $button.disable();
      } else {
        return $button.enable();
      }
    };
    requireInput();
    return $form.on('change input', fieldSelector, requireInput);
  };

  $(function() {
    var $form, hideOrShowHelpBlock;
    $form = $('form.js-requires-input');
    $form.requiresInput();
    hideOrShowHelpBlock = function(form) {
      var selected;
      selected = $('.js-select-namespace option:selected');
      if (selected.length && selected.data('options-parent') === 'groups') {
        return form.find('.help-block').hide();
      } else if (selected.length) {
        return form.find('.help-block').show();
      }
    };
    hideOrShowHelpBlock($form);
    return $('.select2.js-select-namespace').change(function() {
      return hideOrShowHelpBlock($form);
    });
  });

}).call(this);
