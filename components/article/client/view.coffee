Backbone = require 'backbone'
_ = require 'underscore'
Q = require 'bluebird-q'
sd = require('sharify').data
Article = require '../../../models/article.coffee'
Articles = require '../../../collections/articles.coffee'
SlideshowsView = require './slideshows.coffee'
imagesLoaded = require 'imagesloaded'
blurb = require '../../gradient_blurb/index.coffee'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'
CurrentUser = require '../../../models/current_user.coffee'
FollowArtists = require '../../../collections/follow_artists.coffee'
FollowButtonView = require '../../follow_button/view.coffee'
ImageSetView = require './image_set.coffee'
jqueryFillwidthLite = require 'jquery-fillwidth-lite'
JumpView = require '../../jump/view.coffee'
calloutTemplate = -> require('../templates/sections/callout.jade') arguments...
whatToReadNextTemplate = -> require('../templates/what_to_read_next.jade') arguments...
{ crop } = require('embedly-view-helpers')(sd.EMBEDLY_KEY)
mediator = require '../../../lib/mediator.coffee'

require '../../../node_modules/waypoints/lib/jquery.waypoints.js'

DATA =
  published: true
  tier: 1
  channel_id: sd.ARTSY_EDITORIAL_CHANNEL
  sort: '-published_at'

module.exports = class ArticleView extends Backbone.View

  events:
    'click .article-video-play-button' : 'clickPlay'
    'click .article-sa-sticky-right'   : 'toggleArticleToC'
    'click .article-section-image-set': 'toggleModal'
    'click .article-section-toc-link a': 'jumpSmooth'

  initialize: (options = {}) ->
    { @article, @relatedArticles, @gradient, @waypointUrls, @seenArticleIds, @infiniteScroll, @previousHref } = options
    @user = CurrentUser.orNull()
    @loadedCallouts = false
    @jump = new JumpView
    @renderCalloutArticles()
    @initSuperArticle() if @relatedArticles
    @setupWhatToReadNext()
    @followArtists = new FollowArtists []
    @setupFollowButtons()
    @setupTOC()
    @setupImageSetPreviews()
    new SlideshowsView

  maybeFinishedLoading: ->
    if @loadedCallouts
      @setupWaypointUrls() if @waypointUrls
      @addReadMore() if @gradient

  renderCalloutArticles: ->
    Q.allSettled( for section in @article.get('sections') when section.type is 'callout' and section.article.length > 0
      new Article(id: section.article).fetch()
    ).then( (articles) =>
      articles = _.pluck(_.reject(articles, (article) -> article.state is 'rejected'), 'value')
      for section in @article.get('sections') when section.type is 'callout' and section.article.length > 0
        $calloutSection = @$(".article-section-callout-container[data-id=#{section.article}]")
        article = _.find articles, { id: section.article }
        $($calloutSection).append calloutTemplate
          section: section
          calloutArticle: new Article article if article
    ).done =>
      @loadedCallouts = true
      @maybeFinishedLoading()

  setupFollowButtons: ->
    @artists = []
    @$('.artist-follow').each (i, artist) =>
      @artists.push $(artist).data('id')
    @followButtons = @artists.map (id) =>
      new FollowButtonView
        collection: @followArtists
        el: @$(".artist-follow[data-id='#{id}']")
        type: 'Artist'
        followId: id
        context_module: 'article_artist_follow'
        context_page: 'Article page'
        _id: id
        isLoggedIn: not _.isNull CurrentUser.orNull()
    @followArtists.syncFollows @artists

  setupTOC: ->
    blurb $(".article-container[data-id=#{@article.get('id')}] .article-section-toc"),
      limit: 240
      label: 'View All'

  setupImageSetPreviews: ->
    jqueryFillwidthLite($, _, imagesLoaded)
    $('.article-section-container[data-section-type="image_set"]').each (i, value) ->
      $(value).find('.article-section-image-set__images').fillwidthLite({
        targetHeight: 150
        apply: (img, i, gutterSize) ->
          img.$el.width(img.width).css({ 'margin-right' : '5px' })
        gutterSize: 5
        done: -> $(value).css('visibility','visible')
      })

  toggleModal: (e) ->
    # Slideshow Modal
    section = @article.get('sections')[$(e.currentTarget).data('index')]
    imageSet = new ImageSetView
      items: section.images
      user: @user
    $('.article-fixed-share').hide()
    imageSet.on 'closed', -> $('.article-fixed-share').show()

  jumpSmooth: (e) ->
    e.preventDefault()
    name = $(e.currentTarget).attr('href').substring(1)
    @jump.scrollToPosition @$(".is-jump-link[name=#{name}]").offset().top

  initSuperArticle: ->
    @setupSuperArticleStickyNav()
    @$window = $(window)
    @$stickyHeader = @$('.article-sa-sticky-header')
    @$superArticleNavToc = @$('.article-sa-sticky-center')
    throttledScroll = _.throttle((=> @hideArticleToC()), 100)
    @$window.on 'scroll', throttledScroll
    @$el.addClass 'article-sa'

  setupSuperArticleStickyNav: ->
    @$(".article-container").waypoint (direction) =>
      if direction == 'down'
        @$stickyHeader.addClass 'visible'
      else
        @$stickyHeader.removeClass 'visible'

  clickPlay: (event) ->
    $cover = $(event.currentTarget).parent()
    $iframe = $cover.next('.article-section-video').find('iframe')
    $newIframe = $iframe.clone().attr('src', $iframe.attr('src') + '&autoplay=1')
    $iframe.replaceWith $newIframe
    $cover.remove()

  hideArticleToC: ->
    if @$superArticleNavToc.hasClass('visible')
      @$superArticleNavToc.css 'max-height', '0px'
      @$superArticleNavToc.removeClass('visible')

  toggleArticleToC: ->
    if @$superArticleNavToc.hasClass 'visible'
      @hideArticleToC()
    else
      height = @$superArticleNavToc.find('.article-sa-related').height() + 100
      @$superArticleNavToc.css 'max-height', "#{height}px"
      @$superArticleNavToc.addClass 'visible'

  setupWhatToReadNext: =>
    if @infiniteScroll
      Q.allSettled([
        (tagRelated = new Articles).fetch
          data: _.extend _.clone(DATA), tags: if @article.get('tags')?.length then @article.get('tags') else [null]
        (artistRelated = new Articles).fetch
          data: _.extend _.clone(DATA), artist_id: if @article.get('primary_featured_artist_ids')?.length then @article.get('primary_featured_artist_ids')[0]
        (feed = new Articles).fetch
          data: DATA
      ]).then =>
        safeRelated = _.union tagRelated.models, artistRelated.models, feed.models
        safeRelated = _.reject safeRelated, (a) =>
          a.get('id') is @article.get('id') or _.contains @seenArticleIds, a.get('id')
        $(".article-related-widget[data-id=#{@article.get('id')}]").html whatToReadNextTemplate
          related: _.shuffle safeRelated.slice(0,3)
          crop: crop
    else
      $(".article-related-widget[data-id=#{@article.get('id')}]").remove()

  addReadMore: =>
    maxTextHeight = 500 # line-height * line-count
    limit = 0
    textHeight = 0

    # Computes the height of the div where the blur should begin
    # based on the line count excluding images and video
    imagesLoaded $(".article-container[data-id=#{@article.get('id')}] .article-content"), =>
      for textSection in $(".article-container[data-id=#{@article.get('id')}] .article-section-text")
        textHeight = textHeight + $(textSection).height()
        if textHeight >= maxTextHeight
          limit = $(textSection).position().top + $(textSection).outerHeight()
          blurb $(".article-container[data-id=#{@article.get('id')}] .article"),
            limit: limit
            afterApply: =>
              @setupWaypointUrls() if @waypointUrls
              @$(".gradient-blurb-read-more").on 'click', ->
                analyticsHooks.trigger 'readmore', {urlref: @previousHref || ''}
          break

  setupWaypointUrls: =>
    # Scroll down
    $(".article-container[data-id=#{@article.get('id')}]").waypoint (direction) =>
      if direction is 'down'
        window.history.replaceState {}, @article.get('id'), @article.href()
        mediator.trigger 'update:fixedShare',
          url: @article.fullHref(),
          description: @article.shareDescription()

    # Scroll up
    $(".article-container[data-id=#{@article.get('id')}]").waypoint (direction) =>
      if direction is 'up'
        window.history.replaceState {}, @article.get('id'), @article.href()
        mediator.trigger 'update:fixedShare',
          url: @article.fullHref(),
          description: @article.shareDescription()
    , { offset: 'bottom-in-view' }
