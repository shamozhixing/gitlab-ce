((global) => {
  class User {
    constructor(opts) {
      this.opts = opts;
      $('.profile-groups-avatars').tooltip({
        "placement": "top"
      });
      this.initTabs();
      $('.hide-project-limit-message').on('click', function(e) {
        const path = '/';
        $.cookie('hide_project_limit_message', 'false', {
          path: path
        });
        $(this).parents('.project-limit-message').remove();
        e.preventDefault();
        return;
      });
    }

    initTabs() {
      return new UserTabs({
        parentEl: '.user-profile',
        action: this.opts.action
      });
    }
  }

  global.User = User;
})(window.gl);