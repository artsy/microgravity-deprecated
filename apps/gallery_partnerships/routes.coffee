_       = require 'underscore'
request = require 'superagent'
{ APPLICATION_NAME } = require '../../config.coffee'

CONTENT_PATH = '/gallery-partnerships/content.json'

getJSON = (callback) ->
  request.get(
    "http://#{APPLICATION_NAME}.s3.amazonaws.com#{CONTENT_PATH}"
  ).end (err, res) ->
    return callback err if err
    try
      callback null, JSON.parse res.text
    catch e
      callback new Error "Invalid JSON " + e

@index = (req, res, next) ->
  getJSON (err, data) ->
    return next err if err
    res.render 'index', data
