(function() {
  'use strict';

  analyticsHooks.on('auth:login', function(options) {
    analytics.track('Successfully logged in');
  });

  analyticsHooks.on('auth:signup', function(options) {
    analytics.track('Created account');
  });

})();
