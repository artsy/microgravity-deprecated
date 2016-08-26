Backbone = require 'backbone'
sd = require('sharify').data

module.exports = class HeroUnits extends Backbone.Collection

  url: -> "#{sd.API_URL}/api/v1/site_hero_units?enabled=true"

  initialize: ->
    @model = require '../models/hero_unit.coffee'
