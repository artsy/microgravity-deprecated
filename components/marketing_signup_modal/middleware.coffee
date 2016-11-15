url = require 'url'

module.exports = (req, res, next) ->
  sd = res.locals.sd

  host = url.parse(sd.APP_URL).host
  ref = req.get('Referrer')
  paths = sd.MARKETING_SIGNUP_MODAL_PATHS.split(',')

  loggedOut = not req.user?
  fromOutsideArtsy = Boolean ref and not host.match(ref)?
  inWhitelistedPath = req.path in paths

  if loggedOut and inWhitelistedPath and fromOutsideArtsy
    res.locals.showMarketingSignupModal = true
  next()
