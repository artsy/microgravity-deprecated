HeroUnits = require '../../collections/hero_units'
Artworks = require '../../collections/artworks'
FeaturedLinks = require '../../collections/featured_links'
sd = require('sharify').data
Backbone = require 'backbone'
_ = require 'underscore'
Q = require 'bluebird-q'
fetchEOYLists = require '../../components/eoy_artist_list/server.coffee'

module.exports.index = (req, res, next) ->
  heroUnits = new HeroUnits
  Q
    .all [
      heroUnits.fetch()
      fetchEOYLists()
    ]
    .then ([x, eoyData]) ->
      res.locals.sd.EOY_DATA = eoyData
      res.render 'page',
        heroUnits: heroUnits.models
        eoy_2016: eoyData
    .catch (err) ->
      res.render 'page',
        heroUnits: heroUnits.models
        eoy_2016: eoyData
