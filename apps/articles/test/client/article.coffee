_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ resolve } = require 'path'
fixtures = require '../../../../test/helpers/fixtures'
{ fabricate } = require 'antigravity'
Article = require '../../../../models/article.coffee'
Articles = require '../../../../collections/articles.coffee'
{ crop, resize } = require '../../../../components/resizer'
sd = require('sharify').data
moment = require 'moment'

describe 'ArticleIndexView', ->

  before (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        Element: window.Element
      # benv bug that doesn't attach globals to window
      window.jQuery = $
      Backbone.$ = $
      @model = new Article _.extend fixtures.article,
        sections: [
          { type: 'text', body: 'Foo' }
          {
            type: 'artworks',
            ids: ['5321b73dc9dc2458c4000196', '5321b71c275b24bcaa0001a5'],
            layout: 'overflow_fillwidth',
            artworks: []
          }
        ]
        channel_id: '5086df098523e60002000011'
      @options = {
        sd: _.extend sd, { INFINITE_SCROLL: false, ARTICLE: @model.attributes }
        resize: resize
        crop: crop
        article: @model
        moment: moment
        asset: ->
        footerArticles: new Articles [fabricate 'article']
      }
      $.onInfiniteScroll = sinon.stub()
      $.fn.waypoint = sinon.stub()
      sinon.stub Backbone, 'sync'
      @ArticleIndexView = benv.requireWithJadeify resolve(__dirname, '../../client/article'), ['articleTemplate', 'fixedShareTemplate', 'promotedTemplate']
      @ArticleIndexView.__set__ 'sd', { INFINITE_SCROLL: false, ARTICLE: @model.attributes }
      done()

  after ->
    benv.teardown()
    Backbone.sync.restore()

  describe '#initialize static articles', ->

    before (done) ->
      benv.render resolve(__dirname, '../../templates/article.jade'), @options, =>
        @view = new @ArticleIndexView
          el: $('body')
        done()

    it 'renders the template without a loading spinner at the bottom', ->
      $('body').html().should.not.containEql 'article-loading'

  describe '#initFixedShare', ->

    it 'renders the share icons', ->
      @view = new @ArticleIndexView el: $('body')
      $('.article-fixed-share').html().should.containEql 'https://twitter.com/intent/tweet?original_referer=undefined&amp;text=Top Ten Booths at miart 2014 @artsy&amp;url=undefined/article/undefined'
      $('.article-fixed-share').html().should.containEql 'https://www.facebook.com/sharer/sharer.php?u=undefined/article/undefined'
      $('.article-fixed-share').html().should.containEql 'mailto:?subject=Top Ten Booths at miart 2014 @artsy&amp;body=Check out Top Ten Booths at miart 2014 @artsy on Artsy: undefined/article/undefined'


  describe '#initialize infinite scroll articles', ->

    before (done) ->
      @options.sd.INFINITE_SCROLL = true
      @ArticleIndexView.__set__ 'sd', { INFINITE_SCROLL: true }
      benv.render resolve(__dirname, '../../templates/article.jade'), @options, =>
        @ArticleIndexView.__set__ 'ArticleView', sinon.stub()
        @view = new @ArticleIndexView
          el: $('body')
        done()

    it 'renders the template with a loading spinner at the bottom', ->
      $('body').html().should.containEql 'article-loading'

    it 'does not display promoted content banner for non-promoted', ->
      $('.articles-promoted').length.should.equal 0

    it '#nextPage should set offset', ->
      @view.nextPage()
      @view.params.get('offset').should.equal 0
      @view.nextPage()
      @view.params.get('offset').should.equal 5

    it 'excludes super articles', ->
      @view.params.get('is_super_article').should.be.false()

    it 'renders the next page on #render', ->
      articles = [_.extend fixtures.article, { id: '343', sections: [{ type: 'text', body: 'FooLa' }] } ]
      @view.render(@view.collection, results: articles )
      $('.article-container').length.should.equal 2

  describe 'promoted content gallery', ->

    before (done) ->
      @options.sd.PC_ARTSY_CHANNEL = '5086df098523e60002000011'
      @ArticleIndexView.__set__ 'sd', { PC_ARTSY_CHANNEL: '5086df098523e60002000011', ARTICLE: @model.attributes }
      benv.render resolve(__dirname, '../../templates/article.jade'), @options, =>
        @view = new @ArticleIndexView
          el: $('body')
        done()

    it 'displays promoted content banner for partner', ->

      Backbone.sync.args[0][2].success fabricate 'partner'
      Backbone.sync.args[4][2].success fabricate 'partner_profile'
      $('.articles-promoted').attr('href').should.equal '/getty'
      $('.articles-promoted__name').text().should.equal 'Gagosian Gallery'

  describe 'promoted content auction', ->

    before (done) ->
      @options.sd.PC_AUCTION_CHANNEL = '5086df098523e60002000011'
      @options.sd.PC_ARTSY_CHANNEL = '5086df098523e60002000012'
      @ArticleIndexView.__set__ 'sd', { PC_AUCTION_CHANNEL: '5086df098523e60002000011', PC_ARTSY_CHANNEL: '5086df098523e60002000012', ARTICLE: @model.attributes }
      benv.render resolve(__dirname, '../../templates/article.jade'), @options, =>
        @view = new @ArticleIndexView
          el: $('body')
        done()

    it 'displays promoted content banner for auction', ->

      Backbone.sync.args[5][2].success fabricate 'sale'
      $('.articles-promoted').attr('href').should.equal '/sale/whtney-art-party'
      $('.articles-promoted__name').text().should.equal 'Whitney Art Party'
