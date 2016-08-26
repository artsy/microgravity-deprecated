request = require 'superagent'
sd = require('sharify').data

@index = (req, res) ->
  url = "#{sd.ARTSY_URL}/how-auctions-work/data"
  request
    .get(url)
    .end (err, data) ->
      res.locals.sd.HOW_AUCTIONS_WORK = data.body
      res.render 'index'