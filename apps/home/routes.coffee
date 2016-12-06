HeroUnits = require '../../collections/hero_units'
Artworks = require '../../collections/artworks'
FeaturedLinks = require '../../collections/featured_links'
sd = require('sharify').data
Backbone = require 'backbone'
_ = require 'underscore'

module.exports.index = (req, res, next) ->
  heroUnits = new HeroUnits
  heroUnits.fetch
    success: ->
      res.render 'page', heroUnits: heroUnits.models
    error: ->
      res.render 'page', heroUnits: []

module.exports.featuredArtworks = (req, res, next) ->
  new Artworks().fetchSetItemsByKey 'homepage:featured-artworks',
    success: (artworks) ->
      res.render 'featured_works',
        artworks: artworks.models.slice(0, sd.HOMEPAGE_ARTWORKS_COUNT)
    errors: res.backboneError
