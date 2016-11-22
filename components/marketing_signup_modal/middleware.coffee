url = require 'url'

module.exports = (req, res, next) ->
  sd = res.locals.sd

  linkedFromCampaign = req.query['m-id'] is sd.MARKETING_SIGNUP_MODAL_SLUG
  loggedOut = not req.user?

  res.locals.showMarketingSignupModal = true if loggedOut and linkedFromCampaign
  next()
