(function() {
  this.User = (function() {
    function User(opts) {
      this.opts = opts;
      $('.profile-groups-avatars').tooltip({
        "placement": "top"
      });
      this.initTabs();
      $('.hide-project-limit-message').on('click', function(e) {
        var path;
        path = '/';
        $.cookie('hide_project_limit_message', 'false', {
          path: path
        });
        $(this).parents('.project-limit-message').remove();
        return e.preventDefault();
      });
    }

    User.prototype.initTabs = function() {
      return new UserTabs({
        parentEl: '.user-profile',
        action: this.opts.action
      });
    };

    return User;

  })();

}).call(this);
