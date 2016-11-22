{ fabricate } = require 'antigravity'
sinon = require 'sinon'
Backbone = require 'backbone'
rewire = require 'rewire'
routes = rewire '../routes'
Q = require 'bluebird-q'

describe '#index', ->

  beforeEach ->
    sinon.stub Backbone, 'sync'
    routes.index(
      { params: { id: 'foo' } }
      { locals: { sd: {}, asset: (->) }, render: renderStub = sinon.stub(), cacheOnCDN: -> }
    )
    Backbone.sync.args[0][2].success fabricate 'artist', id: 'damien-hershey'
    @templateName = renderStub.args[0][0]
    @templateOptions = renderStub.args[0][1]

  afterEach ->
    Backbone.sync.restore()

  it 'renders the post page', ->
    @templateName.should.equal 'page'
    @templateOptions.artist.get('id').should.equal 'damien-hershey'

describe "#biography", ->

  beforeEach ->
    artist = fabricate 'artist', id: 'damien-hershey'
    routes.__set__ 'metaphysics', => Q.resolve { artist: artist }
    @req = { params: {} }
    @res = render: sinon.stub(), locals: sd: sinon.stub()

  it 'renders the biography page', ->
    routes.biography @req, @res
      .then =>
        @res.render.args[0][0].should.equal 'biography'
        @res.render.args[0][1].artist.id.should.equal 'damien-hershey'

describe '#auctionResults', ->

  beforeEach ->
    sinon.stub Backbone, 'sync'
    @req = { params: {} }
    @res = { locals: { sd: {}, asset: (->) }, render: @render = sinon.stub() }

  afterEach ->
    Backbone.sync.restore()

  it 'renders the auction results page', ->
    routes.auctionResults(@req, @res)
    Backbone.sync.args[0][2].success fabricate 'artist'
    Backbone.sync.args[1][2].success [ fabricate 'auction_result' ]
    @render.args[0][0].should.equal 'auction_results'
    @render.args[0][1].auctionResults[0].get('estimate_text').should.containEql '120,000'
