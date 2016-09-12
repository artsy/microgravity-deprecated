_ = require 'underscore'
sd = require('sharify').data
Backbone = require 'backbone'
editorialSignupLushTemplate = -> require('../templates/editorial_signup_lush.jade') arguments...
Cycle = require '../../../components/cycle/index.coffee'
{ resize } = require '../../../components/resizer/index.coffee'
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

  setupAEArticlePage: ->
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
        @$('.articles-es-cta__container').fadeOut =>
          @$('.articles-es-cta__social').fadeIn()

        @trackSignup @email

  getType: ->
    if @inAEMagazinePage() then 'magazine_fixed' else 'article_fixed'

  trackSignup: (email) ->
    analyticsHooks.trigger('submit:editorial-signup', type: @getType(), email: email)
