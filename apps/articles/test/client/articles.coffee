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

      @articles = "data": {
        "articles": [
          {
            "slug": "artsy-editorial-contemporary-istanbul-tests-turkish-market-rocked-by-terrorism-and-coup-attempt",
            "thumbnail_title": "Contemporary Istanbul Tests Turkish Market Rocked by Terrorism and Coup Attempt",
            "thumbnail_image": "https://artsy-media-uploads.s3.amazonaws.com/8mgvDzCBMloFC6Ee6snHTg%2F9h3a2807_46634.jpg",
            "tier": 1,
            "published_at": "Fri Oct 28 2016 20:14:10 GMT+0000 (UTC)",
            "channel_id": "5759e3efb5989e6f98f77993",
            "author": {
              "name": "Artsy Editorial"
            },
            "contributing_authors": [
              {
                "name": "Isaac Kaplan"
              }
            ]
          },
          {
            "slug": "artsy-editorial-american-couple-donates-380-million-collection-to-musee-d-orsay-and-the-9-other-biggest-news-stories-this-week",
            "thumbnail_title": "American Couple Donates $380 Million Collection to Musée d’Orsay—and the 9 Other Biggest News Stories This Week",
            "thumbnail_image": "https://artsy-media-uploads.s3.amazonaws.com/jc8HvTWVMJdvLmeW6e5iwg%2F2985973992_fcc2d924f3_o.jpg",
            "tier": 1,
            "published_at": "Fri Oct 28 2016 18:16:15 GMT+0000 (UTC)",
            "channel_id": "5759e3efb5989e6f98f77993",
            "author": {
              "name": "Artsy Editorial"
            },
            "contributing_authors": []
          },
          {
            "slug": "artsy-editorial-the-mumbai-jeweler-who-amassed-the-world-s-largest-camera-collection",
            "thumbnail_title": "The Mumbai Jeweler Who Amassed the World’s Largest Camera Collection",
            "thumbnail_image": "https://artsy-media-uploads.s3.amazonaws.com/pK14REBIusHqvlycE695fQ%2FA+%282%29.jpg",
            "tier": 1,
            "published_at": "Fri Oct 28 2016 16:50:00 GMT+0000 (UTC)",
            "channel_id": "5759e3efb5989e6f98f77993",
            "author": {
              "name": "Artsy Editorial"
            },
            "contributing_authors": [
              {
                "name": "Himali Singh Soin"
              }
            ]
          }
        ]
      }
      # @collection = new Articles [ new Article( _.extend fixtures.article, { id: 'foo', author: { profile_handle: 'mrs foo' }} ) , new Article( _.extend fixtures.article, { id: 'bar', author: { profile_handle: 'mrs bar' }} ) ]

      benv.render path.resolve(__dirname, '../../templates/articles.jade'),
        sd: {}
        asset: (->)
        articles: @articles
        crop: ->
        isSentence: ->
        pluck: ->

      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      sinon.stub request, 'post'
      filename = path.resolve(__dirname, '../../client/articles.coffee')
      { MagazineView } = module = benv.requireWithJadeify filename, ['articleTemplate']
      sinon.stub request, 'post'
        .returns
          send: sinon.stub()
          end: sinon.stub().yield @articles

      @view = new MagazineView
        el: $ 'body'
        collection: @articles
        offset: 0

      done()

  after ->
    benv.teardown()

  describe '#initialize', ->

    it 'offset should be zero', ->
      @view.offset.should.equal 0

    it 'sets up infinite scroll on click', ->
      $('.is-show-more-button').click()
      console.log $('.is-show-more-button').attr('display')

  describe '#onInfiniteScroll', ->

    it 'fetches more articles', ->
      @view.onInfiniteScroll()
      Backbone.sync.callCount.should.equal 1
