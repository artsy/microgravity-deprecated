_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
template = -> require('../templates/image_set_modal.jade') arguments...
{ resize } = require '../../resizer/index.coffee'
Flickity = require 'flickity'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'

module.exports = class ImageSetView extends Backbone.View

  initialize: (options) ->
    { @items, @user } = options
    @length = @items.length
    @currentIndex = 0
    @render()

  render: ->
    $('body').prepend template
      items: @items
      resize: resize
      length: @length
    @__postRender__() unless @__postRendered__
    this

  __postRender__: ->
    @trigger 'opened'
    $('body').addClass 'is-scrolling-disabled'
    @slideshow = new Flickity '.image-set-modal',
      prevNextButtons: false
      lazyLoad: true
      setGallerySize: false
      wrapAround: true
      pageDots: false

    $('.image-set-modal-js__close').on 'click', (e) =>
      @close()
      analyticsHooks.trigger 'closed:image-set'

    @__postRendered__ = true

  close: ->
    $('.image-set-modal, .image-set-modal-js__close').remove()
    $('body').removeClass 'is-scrolling-disabled'
    @trigger 'closed'
