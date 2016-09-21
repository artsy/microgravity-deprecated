_ = require 'underscore'
qs = require 'querystring'
sd = require('sharify').data
Backbone = require 'backbone'
editorialSignupLushTemplate = -> require('../templates/editorial_signup_lush.jade') arguments...
Cycle = require '../../../components/cycle/index.coffee'
{ resize } = require '../../../components/resizer/index.coffee'
CTABarView = require '../../../components/cta_bar/view.coffee'
mediator = require '../../../lib/mediator.coffee'
cookies = require '../../../components/cookies/index.coffee'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'

module.exports = class EditorialSignupView extends Backbone.View

  events: ->
    'click .js-article-es': 'onSubscribe'

  initialize: ->
    @setupAEArticlePage() if @inAEArticlePage()
    @setupAEMagazinePage() if @inAEMagazinePage()

  eligibleToSignUp: ->
    (@inAEArticlePage() or @inAEMagazinePage()) and not sd.SUBSCRIBED_TO_EDITORIAL

  inAEArticlePage: ->
    sd.ARTICLE? and sd.ARTICLE.channel_id is sd.ARTSY_EDITORIAL_CHANNEL

  inAEMagazinePage: ->
    sd.CURRENT_PATH is '/articles'

  cycleImages: =>
    cycle = new Cycle
      $el: $('.articles-es-cta__background')
      selector: '.articles-es-cta__images'
      speed: 5000
    cycle.start()

  fetchSignupImages: (cb) ->
    $.ajax
      type: 'GET'
      url: "#{sd.POSITRON_URL}/api/curations/#{sd.EMAIL_SIGNUP_IMAGES_ID}"
      success: (results) ->
        cb results.images
      error: ->
        cb null

  setupCTAWaypoints: =>
    @$el.append @ctaBarView.render().$el
    @ctaBarView.transitionIn()

  setupAEArticlePage: ->
    @ctaBarView = new CTABarView
      mode: 'editorial-signup'
      name: 'dismissed-editorial-signup'
      persist: true
      email: sd.CURRENT_USER?.email or ''
      expires: 2592000
    if not @ctaBarView.previouslyDismissed() and
      @canViewCTAPopup() and
      @eligibleToSignUp() and
      qs.parse(location.search.replace(/^\?/, '')).utm_source isnt 'sailthru'
        @setupCTAWaypoints()
        @trackImpression @ctaBarView.email
    @fetchSignupImages (images) =>
      @$(".article-container[data-id=#{sd.ARTICLE.id}]").append editorialSignupLushTemplate
        email: sd.CURRENT_USER?.email or ''
        images: images
        resize: resize
        isSignup: @eligibleToSignUp()
        page: 'article'
      @cycleImages() if images

  setupAEMagazinePage: ->
    # Show the lush CTA after the 3rd article
    @fetchSignupImages (images) =>
      @$('.article-item')
        .eq(2)
        .after editorialSignupLushTemplate
          email: sd.CURRENT_USER?.email or ''
          images: images
          resize: resize
          isSignup: @eligibleToSignUp()
          page: 'magazine'
        .css('border-bottom', 'none')
      @cycleImages() if images

  canViewCTAPopup: ->
    if viewedArticles = cookies.get('recently-viewed-articles')
      cookies.set('recently-viewed-articles', ( parseInt(viewedArticles) + 1) )
      return parseInt(viewedArticles) > 2 # shows after 4 articles
    else
      cookies.set('recently-viewed-articles', 1, { expires: 2592000 }) #30 days
      return false

  onSubscribe: (e) ->
    @$(e.currentTarget).addClass 'is-loading'
    @email = @$(e.currentTarget).prev('input').val()
    analyticsHooks.trigger('click:editorial-signup', type: @getType())
    $.ajax
      type: 'POST'
      url: '/editorial-signup/form'
      data:
        email: @email
        name: sd.CURRENT_USER?.name or ''
      error: (res) =>
        @$(e.currentTarget).removeClass 'is-loading'
      success: (res) =>
        @$(e.currentTarget).removeClass 'is-loading'
        if @inAEArticlePage() and @canViewCTAPopup()
          @$(e.currentTarget).siblings('.subscribed').addClass('active').fadeIn()
        else
          @$('.articles-es-cta__container').fadeOut =>
            @$('.articles-es-cta__social').fadeIn()

        @trackSignup @email

  getType: ->
    if @inAEMagazinePage() then 'magazine_fixed' else 'article_fixed'

  trackSignup: (email) ->
    analyticsHooks.trigger('submit:editorial-signup', type: @getType(), email: email)

  trackImpression: (email) ->
    setTimeout( =>
      analyticsHooks.trigger('impressions:editorial-signup', articleId: sd.ARTICLE.id, type: @getType(), email: email)
    ,2000)
