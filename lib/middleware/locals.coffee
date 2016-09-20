#
# Middleware that injects common template [locals](http://expressjs.com/api.html#res.locals)
# such as a class to go on <html> to hide the header and footer for the mobile app,
# or generates a session id to be passed among sharify data.
#

_ = require 'underscore'
uuid = require 'node-uuid'
artsyXapp = require 'artsy-xapp'
{ parse } = require 'url'
Referrer = require 'referer-parser'

module.exports = (req, res, next) ->
  ua = req.headers?['user-agent']
  res.locals.sd.CURRENT_PATH = parse(req.url).pathname if req.url?
  res.locals.sd.SESSION_ID = req.session?.id ?= uuid.v1()
  res.locals.sd.USER_AGENT = ua
  res.locals._ = _
  res.locals.htmlClass = if ua?.match(/Artsy-Mobile/) then 'layout-artsy-mobile-app' else ''
  res.locals.htmlClass += ' layout-logged-in' if req.user?
  res.locals.sd.ARTSY_XAPP_TOKEN = artsyXapp.token
  res.locals.sd.REFERRER = referrer = req.get 'Referrer'
  res.locals.sd.MEDIUM = new Referrer(referrer).medium if referrer

  # Attach libraries to locals
  res.locals._ = _

  next()
