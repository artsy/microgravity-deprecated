_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
template = -> require('../templates/image_set_modal.jade') arguments...
{ resize } = require '../../resizer/index.coffee'
FollowArtists = require '../../../collections/follow_artists.coffee'
FollowButtonView = require '../../follow_button/view.coffee'
Flickity = require 'flickity'
CurrentUser = require '../../../models/current_user.coffee'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'

module.exports = class ImageSetView extends Backbone.View

  initialize: (options) ->
    { @items, @user } = options
    @length = @items.length
    @currentIndex = 0
    @followArtists = new FollowArtists []
    @render()
    @setupFollowButtons()
    console.log('setupFollowButtons')

  render: ->
    $('body').prepend template
      items: @items
      resize: resize
      length: @length
    @__postRender__() unless @__postRendered__
    this

  setupFollowButtons: ->
    @artists = []
    $('.artist-follow').each (i, artist) =>
      @artists.push $(artist).data('id')
    @followButtons = @artists.map (id) =>
      new FollowButtonView
        collection: @followArtists
        el: $(".artist-follow[data-id='#{id}']")
        type: 'Artist'
        followId: id
        context_module: 'article_artist_follow'
        context_page: 'Article page'
        _id: id
        isLoggedIn: not _.isNull CurrentUser.orNull()
    @followArtists.syncFollows @artists

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
