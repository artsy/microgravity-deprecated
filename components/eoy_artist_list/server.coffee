request = require 'superagent'
sd = require('sharify').data
cache = require '../../lib/cache.coffee'
Q = require 'bluebird-q'

module.exports = ->
  url = "#{sd.ARTSY_URL}/eoy_2016/data"
  
  Q.promise (resolve, reject) ->
    cache.get "eoy-2016", (err, cachedData) ->
      return reject(err) if err
      return resolve(JSON.parse(cachedData)) if cachedData
      
      request
        .get(url)
        .end (err, data) ->
          return reject(err) if err
          cache.set "eoy-2016", JSON.stringify(data.body)
          resolve(data.body)

        
