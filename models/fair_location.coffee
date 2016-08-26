_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
Relations = require './mixins/relations/location.coffee'

module.exports = class FairLocation extends Backbone.Model

  _.extend @prototype, Relations

  singleLine: ->
    @get 'display'

  toJSONLD: -> @singleLine()
