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

  before (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        Element: window.Element
      # benv bug that doesn't attach globals to window
      window.jQuery = $
      Backbone.$ = $
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
          }
        ]
        contributing_authors: []
        section_ids: []

      benv.render resolve(__dirname, '../templates/index.jade'), {
        article: @article
        asset: (->)
        sd: {}
        resize: ->
        footerArticles: new Backbone.Collection
      }, =>
        @ArticleView = benv.requireWithJadeify(
          resolve(__dirname, '../client/view')
          ['calloutTemplate', 'whatToReadNextTemplate']
        )
        @options = {
          footerArticles: new Backbone.Collection
          slideshowArtworks: null
          article: @article
          calloutArticles: new Backbone.Collection
          author: new Backbone.Model fabricate 'user'
          asset: (->)
          sd: INFINITE_SCROLL: false, RELATED_ARTICLES: []
          moment: require('moment')
          resize: sinon.stub()
        }
        sinon.stub Backbone, 'sync'
        sinon.stub($, 'get').returns { html: '<iframe>Test</iframe>' }
        done()

  after ->
    $.get.restore()
    benv.teardown()
    Backbone.sync.restore()

  describe '#initSuperArticle', ->

    it 'sets up the page for super articles', ->
      @view = new @ArticleView el: $('body'), article: @article
      $('body').hasClass('article-sa').should.be.false()

    it 'sets up the page for super articles', ->
      @view = new @ArticleView el: $('body'), article: @article, relatedArticles: new Articles [fabricate 'article'], infiniteScroll: false
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
        @view = new @ArticleView el: $('body'), article: @article, infiniteScroll: true
        done()

    it 'fetches articles and renders widget', ->
      Backbone.sync.args[0][2].success new Articles fabricate('article',{ id: 'foo', thumbnail_title: 'Foo Title'})
      Backbone.sync.args[1][2].success new Articles fabricate('article',{ id: 'boo', thumbnail_title: 'Boo Title'})
      Backbone.sync.args[2][2].success new Articles fabricate('article',{ id: 'coo', thumbnail_title: 'Coo Title'})
      _.defer =>
        @view.$('.article-related-widget').html().length.should.be.above 1
        @view.$('.article-related-widget').html().should.containEql 'What To Read Next'
        @view.$('.article-related-widget .wtrn-article-container').length.should.equal 3
