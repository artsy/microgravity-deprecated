Q = require 'bluebird-q'
_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
Article = require '../../../models/article'
Articles = require '../../../collections/articles'
CurrentUser = require '../../../models/current_user'
sd = require('sharify').data
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'

describe 'ArticleView', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        Element: window.Element
      # benv bug that doesn't attach globals to window
      window.jQuery = $
      Backbone.$ = $
      $.fn.waypoint = sinon.stub()
      $.fn.imagesLoaded = sinon.stub()
      $.fn.fillwidthLite = (@fillwidthLite = sinon.stub())
      @article = new Article fabricate 'article',
        sections: [
          {
            type: 'text'
            body: '<p><a class="is-follow-link">Damon Zucconi</a><a class="artist-follow" data-id="damon-zucconi"></a></p>'
          },
          {
            type: 'callout'
            article: '123'
            text: ''
            title: ''
            hide_image: false
          },
          {
            type: 'video'
            url: 'http://youtube.com'
            cover_image_url: 'http://artsy.net/cover_image_url.jpg'
            layout: 'full-width'
            background_color: 'black'
          },
          {
            type: 'toc'
            links: [{name: "First Last", value: "First_Last"}]
          },
          {
            type: 'image_set'
            images: [
              {
                type: 'image'
                url: 'https://image.png'
                caption: 'Trademarked'
              }
            ]
          }
        ]
        contributing_authors: []
        section_ids: []

      benv.render resolve(__dirname, '../templates/index.jade'), {
        article: @article
        asset: (->)
        sd: {}
        resize: ->
        crop: ->
        embed: sinon.stub().returns '<iframe>Test-video</iframe>'
        footerArticles: new Backbone.Collection
        superArticle: new Article { super_article: {} }
        relatedArticles: new Articles
      }, =>
        @ArticleView = benv.requireWithJadeify(
          resolve(__dirname, '../client/view'),
          ['calloutTemplate', 'whatToReadNextTemplate']
        )
        @ImageSetView = sinon.stub()
        @ImageSetView::on = sinon.stub()
        @ArticleView.__set__ 'ImageSetView', @ImageSetView
        sinon.stub Backbone, 'sync'
        sinon.stub($, 'get').returns { html: '<iframe>Test-embed</iframe>' }
        done()

  afterEach ->
    $.get.restore()
    benv.teardown()
    Backbone.sync.restore()

  describe '#initSuperArticle', ->

    it 'sets up the page for non-super articles', ->
      @view = new @ArticleView
        el: $('body')
        article: @article
      $('body').hasClass('article-sa').should.be.false()

    it 'sets up the page for super articles', ->
      @view = new @ArticleView
        el: $('body')
        article: @article
        relatedArticles: new Articles [fabricate 'article']
        infiniteScroll: false
      $('body').hasClass('article-sa').should.be.true()
      $('body').html().should.not.containEql 'article-related-widget'

  describe '#setupWhatToReadNext non infinite scroll', ->

    beforeEach ->
      Backbone.sync.restore()
      sinon.stub Backbone, 'sync'

    it 'removes the article related widget when not infinite scroll', ->
      @view = new @ArticleView el: $('body'), article: @article
      $('body').html().should.not.containEql 'article-related-widget'

  describe '#setupFollowButtons', ->

    it 'sets the list of artists in an article with ids', ->
      @view = new @ArticleView el: $('body'), article: @article
      @view.setupFollowButtons()
      @view.artists[0].should.equal 'damon-zucconi'

  describe '#clickPlay', ->

    it 'replaces iFrame with an autoplay attribute', ->
      @view = new @ArticleView el: $('body'), article: @article
      $('.article-video-play-button').click()
      $('.article-section-video iframe').attr('src').should.containEql('autoplay=1')

  describe '#toggleArticleToC', ->

    it 'toggles visibility of TOC on superarticles', ->
      @view = new @ArticleView
        el: $('body')
        article: @article
        relatedArticles: new Articles [fabricate 'article']
      $('.article-sa-sticky-right').click()
      $('.article-sa-sticky-center').css('max-height').should.containEql('100px')

  describe '#seuptImageSetPreviews', ->

    it 'applies jqueryFillwidthLite to image set', ->
      @view = new @ArticleView el: $('body'), article: @article
      @view.setupImageSetPreviews()
      @fillwidthLite.args[0][0].done()
      $('.article-section-container[data-section-type="image_set"]').css('visibility').should.containEql('visible')

  describe '#toggleModal', ->

    it 'renders an imageSet modal with image data', ->
      @view = new @ArticleView el: $('body'), article: @article
      $('.article-section-image-set').click()
      @ImageSetView.args[0][0].items[0].should.have.property('type')
      @ImageSetView.args[0][0].items[0].should.have.property('url')
      @ImageSetView.args[0][0].items[0].should.have.property('caption')

describe 'ArticleView - Infinite scroll', ->

  before (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        Element: window.Element
      # benv bug that doesn't attach globals to window
      window.jQuery = $
      Backbone.$ = $
      @ArticleView = benv.requireWithJadeify(
        resolve(__dirname, '../client/view')
        ['whatToReadNextTemplate', 'calloutTemplate']
      )
      @article = new Article fabricate 'article',
        sections: [
          { type: 'text', body: 'Foo' }
        ]
        contributing_authors: []
        section_ids: []
      @options = {
        footerArticles: new Backbone.Collection
        slideshowArtworks: null
        article: @article
        calloutArticles: new Backbone.Collection
        author: new Backbone.Model fabricate 'user'
        asset: (->)
        sd: INFINITE_SCROLL: true, RELATED_ARTICLES: []
        moment: require('moment')
        resize: sinon.stub()
      }
      sinon.stub Backbone, 'sync'
      done()

  after ->
    benv.teardown()
    Backbone.sync.restore()

  describe '#setupWhatToReadNext infinite scroll', ->

    beforeEach (done) ->
      benv.render resolve(__dirname, '../templates/index.jade'), @options, =>
        @view = new @ArticleView
          el: $('body')
          article: @article
          infiniteScroll: true
        done()

    it 'fetches articles and renders widget', ->
      Backbone.sync.args[0][2].data.tags.should.ok()
      Backbone.sync.args[1][2].data.should.have.property('artist_id')
      Backbone.sync.args[2][2].data.should.not.have.property('artist_id')
      Backbone.sync.args[2][2].data.should.not.have.property('tags')
      Backbone.sync.args[0][2].success new Articles fabricate('article',{ id: 'foo', thumbnail_title: 'Foo Title'})
      Backbone.sync.args[1][2].success new Articles fabricate('article',{ id: 'boo', thumbnail_title: 'Boo Title'})
      Backbone.sync.args[2][2].success new Articles fabricate('article',{ id: 'coo', thumbnail_title: 'Coo Title'})
      _.defer =>
        @view.$('.article-related-widget').html().length.should.be.above 1
        @view.$('.article-related-widget').html().should.containEql 'What To Read Next'
        @view.$('.article-related-widget .wtrn-article-container').length.should.equal 3
