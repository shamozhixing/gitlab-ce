(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Profile = (function() {
    function Profile(opts) {
      var cropOpts, ref;
      if (opts == null) {
        opts = {};
      }
      this.onSubmitForm = bind(this.onSubmitForm, this);
      this.form = (ref = opts.form) != null ? ref : $('.edit-user');
      $('.js-preferences-form').on('change.preference', 'input[type=radio]', function() {
        return $(this).parents('form').submit();
      });
      $('#user_notification_email').on('change', function() {
        return $(this).parents('form').submit();
      });
      $('.update-username').on('ajax:before', function() {
        $('.loading-username').show();
        $(this).find('.update-success').hide();
        return $(this).find('.update-failed').hide();
      });
      $('.update-username').on('ajax:complete', function() {
        $('.loading-username').hide();
        $(this).find('.btn-save').enable();
        return $(this).find('.loading-gif').hide();
      });
      $('.update-notifications').on('ajax:success', function(e, data) {
        if (data.saved) {
          return new Flash("Notification settings saved", "notice");
        } else {
          return new Flash("Failed to save new settings", "alert");
        }
      });
      this.bindEvents();
      cropOpts = {
        filename: '.js-avatar-filename',
        previewImage: '.avatar-image .avatar',
        modalCrop: '.modal-profile-crop',
        pickImageEl: '.js-choose-user-avatar-button',
        uploadImageBtn: '.js-upload-user-avatar',
        modalCropImg: '.modal-profile-crop-image'
      };
      this.avatarGlCrop = $('.js-user-avatar-input').glCrop(cropOpts).data('glcrop');
    }

    Profile.prototype.bindEvents = function() {
      return this.form.on('submit', this.onSubmitForm);
    };

    Profile.prototype.onSubmitForm = function(e) {
      e.preventDefault();
      return this.saveForm();
    };

    Profile.prototype.saveForm = function() {
      var avatarBlob, formData, self;
      self = this;
      formData = new FormData(this.form[0]);
      avatarBlob = this.avatarGlCrop.getBlob();
      if (avatarBlob != null) {
        formData.append('user[avatar]', avatarBlob, 'avatar.png');
      }
      return $.ajax({
        url: this.form.attr('action'),
        type: this.form.attr('method'),
        data: formData,
        dataType: "json",
        processData: false,
        contentType: false,
        success: function(response) {
          return new Flash(response.message, 'notice');
        },
        error: function(jqXHR) {
          return new Flash(jqXHR.responseJSON.message, 'alert');
        },
        complete: function() {
          window.scrollTo(0, 0);
          return self.form.find(':input[disabled]').enable();
        }
      });
    };

    return Profile;

  })();

  $(function() {
    $(document).on('focusout.ssh_key', '#key_key', function() {
      var $title, comment;
      $title = $('#key_title');
      comment = $(this).val().match(/^\S+ \S+ (.+)\n?$/);
      if (comment && comment.length > 1 && $title.val() === '') {
        return $title.val(comment[1]).change();
      }
    });
    if (gl.utils.getPagePath() === 'profiles') {
      return new Profile();
    }
  });

}).call(this);
