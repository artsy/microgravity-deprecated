bootstrap = require '../../../components/layout/bootstrap.coffee'
_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
Articles = require '../../../collections/articles.coffee'
PoliteInfiniteScrollView = require '../../../components/polite_infinite_scroll/client/view.coffee'
EditorialSignupView = require './editorial_signup.coffee'
articleTemplate = -> require('../templates/articles_feed.jade') arguments...
{ crop } = require '../../../components/resizer/index.coffee'
request = require 'superagent'
{ toSentence } = require 'underscore.string'

module.exports.MagazineView = class MagazineView extends PoliteInfiniteScrollView

  initialize: ({@offset})->
    @$('.is-show-more-button').click =>
      @onInfiniteScroll()
      $.onInfiniteScroll => @onInfiniteScroll()

  onInfiniteScroll: ->
    @offset += 30
    query = """
      {
        articles(published: true, limit: 30, sort: "-published_at", featured: true, offset: #{@offset} ) {
          slug
          thumbnail_title
          thumbnail_image
          tier
          published_at
          channel_id
          author{
            name
          }
          contributing_authors{
            name
          }
        }
      }
    """
    return if @finishedScrolling
    request.post(sd.POSITRON_URL + '/api/graphql')
      .send(
        query: query
      ).end (err, response) =>
        articles = response.body.data.articles
        if articles.length
          @collection = articles
          @offset += 20
          @onSync()
        else
          @onFinishedScrolling() if articles.length is 0

  onSync: =>
    if @collection.length > 0
      html = articleTemplate
        articles: @collection
        crop: crop
        pluck: _.pluck
        toSentence: toSentence
      @$('.js-articles-feed').append html
      @$('.js-articles-feed img').error -> $(@).closest('.articles-item').hide()
      @$('#articles-feed-empty-message').hide()
    else
      @$('#articles-feed-empty-message').show()

module.exports.init = ->
  bootstrap()

  new MagazineView
    el: $('#articles-page')
    collection: sd.ARTICLES
    offset: 0

  new EditorialSignupView el: $('body')
