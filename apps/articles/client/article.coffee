Backbone = require 'backbone'
_ = require 'underscore'
sd = require('sharify').data
Article = require '../../../models/article.coffee'
Articles = require '../../../collections/articles.coffee'
ArticleView = require '../../../components/article/client/view.coffee'
{ resize } = require '../../../components/resizer/index.coffee'
embed = require 'embed-video'
moment = require 'moment'
mediator = require '../../../lib/mediator.coffee'
EditorialSignupView = require './editorial_signup.coffee'
Sale = require '../../../models/sale.coffee'
Partner = require '../../../models/partner.coffee'
Profile = require '../../../models/profile.coffee'
articleTemplate = -> require('../../../components/article/templates/index.jade') arguments...
fixedShareTemplate = -> require('../templates/fixed_share.jade') arguments...
promotedTemplate = -> require('../templates/promoted_content.jade') arguments...

require '../../../node_modules/waypoints/lib/jquery.waypoints.js'

module.exports = class ArticleIndexView extends Backbone.View

  initialize: (options) ->
    @params = new Backbone.Model
      channel_id: sd.ARTSY_EDITORIAL_CHANNEL
      published: true
      tier: 1
      sort: '-published_at'
      is_super_article: false
      limit: 5

    @article = new Article sd.ARTICLE
    @displayedArticles = [@article.get('slug')]
    @collection = new Articles
      data: @params.toJSON()

    # Main Article
    new ArticleView
      el: $('body')
      article: @article
      relatedArticles: sd.RELATED_ARTICLES
      waypointUrls: true
      seenArticleIds: []
      infiniteScroll: sd.INFINITE_SCROLL

    @updateFixedShare @article.fullHref(), @article.shareDescription()

    @setupInfiniteScroll() if sd.INFINITE_SCROLL
    @setupPromotedContent() if @article.get('channel_id') is sd.PC_ARTSY_CHANNEL or
      @article.get('channel_id') is sd.PC_AUCTION_CHANNEL

  setupInfiniteScroll: ->
    @listenTo @collection, 'sync', @render

    @listenTo @params, 'change:offset', =>
      $('#article-loading').addClass 'is-loading'
      @collection.fetch
        remove: false
        data: @params.toJSON()
        complete: => $('#article-loading').removeClass 'is-loading'

    mediator.on 'update:fixedShare', (options) =>
      @updateFixedShare(options.url, options.description)

    $.onInfiniteScroll(@nextPage)
    $(window).scroll(_.debounce( (-> Waypoint.refreshAll()), 100))

  render: (collection, response) =>
    if response
      # Reject articles that are the original article, fullscreen, or super/subsuper
      articles = _.reject response.results, (a) =>
        (a.id is @article.id) or (a.hero_section?.type is 'fullscreen') or (_.contains(sd.SUPER_SUB_ARTICLE_IDS, a.id))
      @displayedArticles = @displayedArticles.concat _.pluck(articles, 'slug')

      for article in articles
        # Setup and append article template
        article = new Article article
        $("#article-body-container").append articleTemplate
          article: article
          sd: sd
          resize: resize
          moment: moment
          embed: embed

        previousHref = @displayedArticles[@displayedArticles.indexOf(article.get('slug'))-1]
        # Initialize client
        new ArticleView
          el: $(".article-container[data-id=#{article.get('id')}]")
          article: article
          gradient: true
          waypointUrls: true
          seenArticleIds: (_.pluck articles, 'id').slice(0,5)
          infiniteScroll: true
          previousHref: previousHref

  nextPage: =>
    @params.set offset: (@params.get('offset') + 5) or 0

  updateFixedShare: (url, description) ->
    $('.js--article-fixed-share').html fixedShareTemplate
      url: url
      description: description

  setupPromotedContent: =>
    if @article.get('channel_id') is sd.PC_ARTSY_CHANNEL
      new Partner(id: @article.get('partner_ids')?[0]).fetch
        success: (partner) =>
          new Profile(id: partner.get('default_profile_id')).fetch
            success: (profile) =>
              @renderPromotedTemplate( partner.get('name'), profile.href() )
    else if @article.get('channel_id') is sd.PC_AUCTION_CHANNEL
      new Sale(id: @article.get('auction_ids')?[0]).fetch
        success: (sale) =>
          @renderPromotedTemplate( sale.get('name'), sale.href() )

  renderPromotedTemplate: (name, href) ->
    console.log 'promoted template'
    $('.article-section-header').hide()
    $('#article-body-container').addClass('promoted').prepend promotedTemplate
      name: name
      href: href

module.exports.init = ->
  new ArticleIndexView el: $('body')
  new EditorialSignupView el: $('body')
