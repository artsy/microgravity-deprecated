url = require 'url'

module.exports = (req, res, next) ->
  sd = res.locals.sd
  inWhitelistedPath = req.path in sd.MARKETING_SIGNUP_MODAL_PATHS.split(',')
  host = url.parse(sd.APP_URL).host
  ref = req.get('Referrer')
  fromOutsideArtsy = Boolean ref and not host.match(ref)?
  if inWhitelistedPath and fromOutsideArtsy
    res.locals.showMarketingSignupModal = true
  next()
