// Home Screen app extras: the count on the app icon, the screen kept on
// while a meal is analysed, and keeping the stored meals.
(function () {
  'use strict';

  function standalone() {
    try {
      return navigator.standalone === true || matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  // Meals and photos live in IndexedDB, which a browser may clear when the
  // device runs low on space. The installed app asks to be kept out of that.
  // Asking reads and writes no data: granted, the storage is only exempt
  // from clearing; refused, everything stays as it was. Only the installed
  // app asks, because Firefox asks the user about it.
  function keepStorage() {
    var storage = navigator.storage;
    if (!storage || !storage.persist || !storage.persisted || !standalone()) return;
    storage
      .persisted()
      .then(function (kept) {
        if (!kept) return storage.persist();
      })
      .catch(function () {});
  }
  keepStorage();

  // 'granted', 'denied', 'default' (not asked yet) or 'unsupported'. Safari
  // shows a count only once notifications are allowed; browsers without
  // notifications show it without asking.
  window.kaloratBadgePermission = function () {
    if (!('setAppBadge' in navigator)) return 'unsupported';
    if (typeof Notification === 'undefined') return 'granted';
    return Notification.permission;
  };

  // Must run in a tap: Safari only asks then.
  window.kaloratRequestBadgePermission = function () {
    if (typeof Notification === 'undefined' || !Notification.requestPermission) {
      return Promise.resolve(window.kaloratBadgePermission());
    }
    return Promise.resolve(Notification.requestPermission()).then(
      function () {
        return window.kaloratBadgePermission();
      },
      function () {
        return 'denied';
      }
    );
  };

  window.kaloratSetBadge = function (count) {
    try {
      var done = count > 0 ? navigator.setAppBadge(count) : navigator.clearAppBadge();
      if (done && done.catch) done.catch(function () {});
    } catch (_) {}
  };

  // The screen lock ends a wake lock when the app is hidden; it is taken
  // again when the app comes back while it is still wanted.
  var wanted = false;
  var lock = null;
  var asking = false;
  function acquire() {
    if (!wanted || lock || asking || document.visibilityState !== 'visible') return;
    if (!navigator.wakeLock || !navigator.wakeLock.request) return;
    asking = true;
    navigator.wakeLock
      .request('screen')
      .then(function (sentinel) {
        asking = false;
        if (!wanted) {
          sentinel.release().catch(function () {});
          return;
        }
        lock = sentinel;
        sentinel.addEventListener('release', function () {
          if (lock === sentinel) lock = null;
        });
      })
      .catch(function () {
        asking = false;
      });
  }
  window.kaloratKeepScreenOn = function (on) {
    wanted = !!on;
    if (wanted) {
      acquire();
    } else if (lock) {
      var sentinel = lock;
      lock = null;
      sentinel.release().catch(function () {});
    }
  };
  document.addEventListener('visibilitychange', acquire);
})();
