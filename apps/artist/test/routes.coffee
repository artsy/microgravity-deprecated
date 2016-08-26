{ fabricate } = require 'antigravity'
sinon = require 'sinon'
routes = require '../routes'
Backbone = require 'backbone'

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
    sinon.stub Backbone, 'sync'
    routes.biography(
      { params: { id: 'foo' } }
      { locals: { sd: {}, asset: (->) }, render: renderStub = sinon.stub(), cacheOnCDN: -> }
    )
    Backbone.sync.args[0][2].success fabricate 'artist', id: 'damien-hershey'
    @templateName = renderStub.args[0][0]
    @templateOptions = renderStub.args[0][1]

  afterEach ->
    Backbone.sync.restore()

  it 'renders the biography page', ->
    @templateName.should.equal 'biography'
    @templateOptions.artist.get('id').should.equal 'damien-hershey'

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
