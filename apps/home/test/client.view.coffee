_ = require 'underscore'
Backbone = require 'backbone'
HeroUnits = require '../../../collections/hero_units'
{ fabricate } = require 'antigravity'
sinon = require 'sinon'
benv = require 'benv'
{ resolve } = require 'path'

describe 'HomePageView', ->

  beforeEach (done) ->
    benv.setup =>
      benv.expose
        $: benv.require 'jquery'
        Element: window.Element

      Backbone.$ = $
      benv.render resolve(__dirname, '../templates/page.jade'), {
        heroUnits: new HeroUnits([
          fabricate 'site_hero_unit'
          fabricate 'site_hero_unit'
          fabricate 'site_hero_unit'
        ]).models
        sd: {}
      }, =>
        @HomePageView = benv.requireWithJadeify resolve(__dirname, '../client/view'),
          ['featuredItemsTemplate', 'currentShowsTemplate', 'artworkColumnsTemplate']
        sinon.stub Backbone, 'sync'
        @view = new @HomePageView
        Backbone.sync.restore()
        sinon.stub Backbone, 'sync'
        done()

  afterEach ->
    benv.teardown()
    Backbone.sync.restore()

  describe '#initialize', ->

    it 'renders shows on sync', ->
      @view.onSync = sinon.stub()
      @view.initialize()
      @view.collection.trigger 'sync'
      @view.onSync.called.should.be.ok()

    xit 'on infinite scroll calls next page on the collection with no arguments', ->
      @view.shows.nextPage = sinon.stub()
      $(window).trigger 'infiniteScroll'
      @view.shows.nextPage.args[0].length.should.equal 0

    it 'sets up hero units', ->
      @view.onSync = sinon.stub()
      @view.initialize()
      @view.slideshow.element.id.should.equal 'carousel-track'
      @view.slideshow.options.autoPlay.should.equal 10000

  describe '#renderCurrentShows', ->

    it 'renders the current shows', ->
      @view.collection.reset [
        fabricate 'show', name: 'Kittens on the wall'
      ]
      @view.onSync()
      @view.$el.html().should.containEql 'Kittens on the wall'

  xdescribe '#onSwipeStart', ->

  xdescribe '#onSwipeEnd', ->
