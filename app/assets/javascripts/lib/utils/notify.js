(function() {
  (function(w) {
    var notificationGranted, notifyMe, notifyPermissions;
    notificationGranted = function(message, opts, onclick) {
      var notification;
      notification = new Notification(message, opts);
      setTimeout(function() {
        return notification.close();
      }, 8000);
      if (onclick) {
        return notification.onclick = onclick;
      }
    };
    notifyPermissions = function() {
      if ('Notification' in window) {
        return Notification.requestPermission();
      }
    };
    notifyMe = function(message, body, icon, onclick) {
      var opts;
      opts = {
        body: body,
        icon: icon
      };
      if (!('Notification' in window)) {

      } else if (Notification.permission === 'granted') {
        return notificationGranted(message, opts, onclick);
      } else if (Notification.permission !== 'denied') {
        return Notification.requestPermission(function(permission) {
          if (permission === 'granted') {
            return notificationGranted(message, opts, onclick);
          }
        });
      }
    };
    w.notify = notifyMe;
    return w.notifyPermissions = notifyPermissions;
  })(window);

}).call(this);
