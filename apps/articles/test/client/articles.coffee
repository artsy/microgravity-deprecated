_ = require 'underscore'
benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
path = require 'path'
{ fabricate } = require 'antigravity'
Articles = require '../../../../collections/articles'
Article = require '../../../../models/article'
fixtures = require '../../../../test/helpers/fixtures'

describe 'MagazineView', ->

  before (done) ->
    benv.setup =>
      @collection = new Articles [ new Article( _.extend fixtures.article, { id: 'foo', author: { profile_handle: 'mrs foo' }} ) , new Article( _.extend fixtures.article, { id: 'bar', author: { profile_handle: 'mrs bar' }} ) ]

      benv.render path.resolve(__dirname, '../../templates/articles.jade'),
        sd: {}
        asset: (->)
        articles: @collection.models

      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      sinon.stub Backbone, 'sync'
      filename = path.resolve(__dirname, '../../client/articles.coffee')
      { MagazineView } = module = benv.requireWithJadeify filename, ['articleTemplate']
      @PoliteInfiniteScrollView = module.__get__ 'PoliteInfiniteScrollView'
      @politeScroll = sinon.stub(@PoliteInfiniteScrollView.prototype, 'initialize')

      @view = new MagazineView
        el: $ 'body'
        collection: @collection
        params:
          offset: 0

      done()

  after ->
    benv.teardown()
    Backbone.sync.restore()
    @politeScroll.restore()

  describe '#initialize', ->

    it 'offset should be zero', ->
      @view.params.offset.should.equal 0

    it 'fetches an initial collection', ->
      @view.onInitialFetch()
      $('.article-item').length.should.equal 2

  describe '#onInfiniteScroll', ->

    it 'fetches more articles', ->
      @view.onInfiniteScroll()
      Backbone.sync.callCount.should.equal 1
