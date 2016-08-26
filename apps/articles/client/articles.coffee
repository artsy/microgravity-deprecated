bootstrap = require '../../../components/layout/bootstrap.coffee'
_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
Articles = require '../../../collections/articles.coffee'
PoliteInfiniteScrollView = require '../../../components/polite_infinite_scroll/client/view.coffee'
EditorialSignupView = require './editorial_signup.coffee'
articleTemplate = -> require('../templates/articles_feed.jade') arguments...

module.exports.MagazineView = class MagazineView extends PoliteInfiniteScrollView

  initialize: ({@offset, @params})->
    @collection.on 'sync', @onSync
    @onInitialFetch()

    @$('.is-show-more-button').click => @startInfiniteScroll()

  onInfiniteScroll: ->
    return if @finishedScrolling
    @collection.fetch
      data: @params
      remove: false
      success: (articles, res) =>
        @params.offset += 10
        @onFinishedScrolling() if res.length is 0

  onSync: =>
    if @collection.length > 0
      html = articleTemplate articles: @collection.models
      @$('.js-articles-feed').html html
      @$('.js-articles-feed img').error -> $(@).closest('.articles-item').hide()
      @$('#articles-feed-empty-message').hide()
    else
      @$('#articles-feed-empty-message').show()

module.exports.init = ->
  bootstrap()

  articles = new Articles sd.ARTICLES

  new MagazineView
    el: $('#articles-page')
    collection: articles
    params:
      published: true
      limit: 10
      offset: 10
      sort: '-published_at'
      featured: true

  new EditorialSignupView el: $('body')
