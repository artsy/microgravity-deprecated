(function () {
  'use strict'

  $('.partner-profile-contact-email a').click(function (e) {
    analytics.track('Clicked Contact Gallery Via Email', {
      gallery_id: $(e.currentTarget).data('id')
    })
  })

  $('.partner-profile-contact-website a').click(function (e) {
    analytics.track('Clicked Gallery Website', {
      gallery_id: $(e.currentTarget).data('id')
    })
  })
})()