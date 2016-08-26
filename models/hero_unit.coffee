_ = require 'underscore'
Backbone = require 'backbone'
{ Markdown } = require 'artsy-backbone-mixins'

module.exports = class HeroUnit extends Backbone.Model

  _.extend @prototype, Markdown

  cssClass: ->
    'home-page-hero-unit-' + @get('mobile_menu_color_class')