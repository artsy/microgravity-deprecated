HeroUnits = require '../../collections/hero_units'
Artworks = require '../../collections/artworks'
FeaturedLinks = require '../../collections/featured_links'
sd = require('sharify').data
Backbone = require 'backbone'
_ = require 'underscore'
Q = require 'bluebird-q'

module.exports.index = (req, res, next) ->
  heroUnits = new HeroUnits
  Q
    .all [
      heroUnits.fetch()
    ]
    .then ([x, eoyData]) ->
      res.render 'page',
        heroUnits: heroUnits.models
    .catch (err) ->
      res.render 'page',
        heroUnits: heroUnits.models
        eoy_2016: eoyData
