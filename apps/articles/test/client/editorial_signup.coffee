_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ resolve } = require 'path'

describe 'EditorialSignupView', ->

  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      $.fn.waypoint = sinon.stub()
      sinon.stub($, 'ajax')
      Backbone.$ = $
      @$el = $('<div><div class="article-container" data-id="123"</div></div>')
      @EditorialSignupView = benv.requireWithJadeify resolve(__dirname, '../../client/editorial_signup'), ['editorialSignupLushTemplate']
      @cycleImages = sinon.stub @EditorialSignupView::, 'cycleImages'
      sinon.stub @EditorialSignupView::, 'trackSignup'
      @ctaBarView = sinon.stub().returns
        render: sinon.stub().returns { $el: '<div class="cta-bar-magazine"></div>' }
        previouslyDismissed: sinon.stub()
        transitionIn: sinon.stub()
      @EditorialSignupView.__set__ 'CTABarView', @ctaBarView
      @view = new @EditorialSignupView el: @$el
      done()

  after ->
    $.ajax.restore()
    benv.teardown()

  describe '#eligibleToSignUp', ->

    it 'checks is not in editorial article or magazine', ->
      @EditorialSignupView.__set__ 'sd',
        ARTICLE: null
        SUBSCRIBED_TO_EDITORIAL: false
        CURRENT_PATH: ''
      @view.eligibleToSignUp().should.not.be.ok()

    it 'checks if in article or magazine', ->
      @EditorialSignupView.__set__ 'sd',
        ARTICLE: null
        SUBSCRIBED_TO_EDITORIAL: false
        CURRENT_PATH: '/articles'
      @view.eligibleToSignUp().should.be.ok()

  describe '#onSubscribe', ->

    it 'removes the form when successful', ->
      @EditorialSignupView.__set__ 'sd',
        ARTICLE: { channel_id: '123', id: '123' }
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: false
        MEDIUM: 'social'
      @view.initialize()
      @view.onSubscribe({currentTarget: $('<div></div>')})
      $.ajax.args[0][0].success
        images: [
          { src: 'image1.jpg' },
          { src: 'image2.jpg' },
          { src: 'image3.jpg' },
        ]
      $.ajax.args[1][0].success()
      _.defer =>
        $(@$el).children("articles-es-cta__container").css('display').should.containEql 'none'
        $(@$el).children('.articles-es-cta__social').css('display').should.containEql 'block'

    it 'removes the loading spinner if there is an error', ->
      $.ajax.yieldsTo('error')
      @EditorialSignupView.__set__ 'sd',
        ARTICLE: channel_id: '123'
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: false
        MEDIUM: 'social'
      $subscribe = $('<div></div>')
      @view.onSubscribe({currentTarget: $subscribe})
      $($subscribe).hasClass('loading-spinner').should.be.false()

  describe '#canViewCTAPopup', ->

    it 'returns false with no recently-viewed-articles cookie', ->

      @EditorialSignupView.__set__ 'sd',
        ARTICLE: { channel_id: '123', id: '123' }
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: false
      @EditorialSignupView.__set__ 'cookies',
        set: (@setStub = sinon.stub()),
        get: (@getStub = sinon.stub())
      @view.canViewCTAPopup().should.be.false()

    it 'returns false when already subscribed', ->

     @EditorialSignupView.__set__ 'sd',
        ARTICLE: { channel_id: '123', id: '123' }
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: true
      @EditorialSignupView.__set__ 'cookies',
        set: (@setStub = sinon.stub()),
        get: (@getStub = sinon.stub().returns('4'))
      @view.canViewCTAPopup().should.be.false()

    it 'returns true when recently-viewed-articles cookie', ->

      @EditorialSignupView.__set__ 'sd',
        ARTICLE: { channel_id: '123', id: '123' }
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: false
      @EditorialSignupView.__set__ 'cookies',
        set: (@setStub = sinon.stub()),
        get: (@getStub = sinon.stub().returns('4'))
      @view.canViewCTAPopup().should.be.true()

    it 'returns false when source is sailthru', ->

      @EditorialSignupView.__set__ 'sd',
        ARTICLE: { channel_id: '123', id: '123' }
        ARTSY_EDITORIAL_CHANNEL: '123'
        SUBSCRIBED_TO_EDITORIAL: false
      @EditorialSignupView.__set__ 'qs',
        parse: sinon.stub().returns({utm_source: 'sailthru'})
      @view.canViewCTAPopup().should.be.false()

  describe '#setupAEMagazinePage', ->

    it 'sets up modal for /articles', ->
      @EditorialSignupView.__set__ 'sd',
        SUBSCRIBED_TO_EDITORIAL: false
        CURRENT_PATH: '/articles'
      @view.setupAEMagazinePage()
      @view.$el.html().should.containEql 'cta-bar-magazine'
