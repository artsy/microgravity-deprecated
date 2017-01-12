{ fabricate } = require 'antigravity'
_ = require 'underscore'
Q = require 'bluebird-q'
sinon = require 'sinon'
rewire = require 'rewire'
routes = rewire '../routes'
Backbone = require 'backbone'

describe '#index', ->

  beforeEach ->
    sinon.stub(Backbone, 'sync').yieldsTo 'success', [
      fabricate 'site_hero_unit', heading: 'Artsy Editorial focus on Kittens'
      fabricate 'site_hero_unit'
    ]

  afterEach ->
    Backbone.sync.restore()

  it 'renders the hero units', (done) ->
    routes.index(
      {}
      { locals: { sd: { } }, render: renderStub = sinon.stub() }
    )
    _.defer =>
      renderStub.args[0][0].should.equal 'page'
      renderStub.args[0][1].heroUnits[0].get('heading').should.equal 'Artsy Editorial focus on Kittens'
      done()
