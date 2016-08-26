#
# Main app file that runs setup code and starts the server process.
# This code should be kept to a minimum. Any setup code that gets large should be
# abstracted into modules under /lib.
#

{ NODETIME_ACCOUNT_KEY, APPLICATION_NAME, NODE_ENV, PORT, API_URL, CLIENT_ID,
  CLIENT_SECRET } = require './config'
newrelic = require 'artsy-newrelic'
artsyXapp = require 'artsy-xapp'
express = require 'express'
setup = require './lib/setup'
cache = require './lib/cache'

# Setup the project app
module.exports = app = express()
app.use newrelic

# Attempt to connect to Redis. If it fails, no worries, the app will move on
# without caching.
cache.setup ->
  # Get an xapp token
  artsyXapp.init { url: API_URL, id: CLIENT_ID, secret: CLIENT_SECRET }, ->
    setup app
    # Start server
    app.listen PORT, ->
      console.log "Microgravity listening on port " + PORT
      process.send? 'listening'

# Crash if we can't get/refresh an xapp token
artsyXapp.on 'error', (e) -> console.warn(e); process.exit(1)
