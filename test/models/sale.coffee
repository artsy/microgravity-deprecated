sinon = require 'sinon'
moment = require 'moment'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Sale = require '../../models/sale'

describe 'Sale', ->
  beforeEach ->
    sinon.stub Backbone, 'sync'
    @sale = new Sale fabricate 'sale', id: 'whtney-art-party'

  afterEach ->
    Backbone.sync.restore()

  describe '#fetchArtworks', ->
    it 'fetches the sale artworks', ->
      @sale.fetchArtworks()
      Backbone.sync.args[0][1].url().should.containEql '/api/v1/sale/whtney-art-party/sale_artworks'

  describe '#registerUrl', ->
    it 'points to the secure auction registration page'
    it 'points to the signup page when not logged in'

  describe '#calculateOffsetTimes', ->
    describe 'client time preview', ->
      beforeEach ->
        @clock = sinon.useFakeTimers()
        @sale.set
          is_auction: true
          start_at: moment().add(1, 'minutes').format()
          end_at: moment().add(3, 'minutes').format()

      afterEach ->
        @clock.restore()

      it 'reflects server preview state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().format() }
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at'))).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at'))).should.be.ok()
        @sale.get('auctionState').should.equal 'preview'

      it 'reflects server open state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().add(2, 'minutes').format() }
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at')).subtract(2, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at')).subtract(2, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'open'

      it 'reflects server closed state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().add(4, 'minutes').format() }
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at')).subtract(4, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at')).subtract(4, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'closed'

    describe 'client time open', ->
      beforeEach ->
        @clock = sinon.useFakeTimers()
        @sale.set
          is_auction: true
          start_at: moment().add(1, 'minutes').format()
          end_at: moment().add(3, 'minutes').format()
        @clock.tick(120000)

      afterEach ->
        @clock.restore()

      it 'reflects server preview state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().subtract(2, 'minutes').format() }
        @sale.get('offsetStartAtMoment')
          .isSame(moment(@sale.get('start_at')).add(2, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment')
          .isSame(moment(@sale.get('end_at')).add(2, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'preview'

      it 'reflects server open state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().format() }
        @sale.get('auctionState').should.equal 'open'
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at'))).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at'))).should.be.ok()

      it 'reflects server closed state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().add(2, 'minutes').format() }
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at')).subtract(2, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at')).subtract(2, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'closed'

    describe 'client time closed', ->
      beforeEach ->
        @clock = sinon.useFakeTimers()
        @sale.set
          is_auction: true
          start_at: moment().add(1, 'minutes').format()
          end_at: moment().add(3, 'minutes').format()
        @clock.tick(240000)

      afterEach ->
        @clock.restore()

      it 'reflects server preview state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().subtract(4, 'minutes').format() }
        @sale.get('offsetStartAtMoment')
          .isSame(moment(@sale.get('start_at')).add(4, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment')
          .isSame(moment(@sale.get('end_at')).add(4, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'preview'

      it 'reflects server open state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().subtract(2, 'minutes').format() }
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at')).add(2, 'minutes')).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at')).add(2, 'minutes')).should.be.ok()
        @sale.get('auctionState').should.equal 'open'

      it 'reflects server closed state', ->
        @sale.calculateOffsetTimes()
        Backbone.sync.args[0][2].success { iso8601: moment().format() }
        @sale.get('auctionState').should.equal 'closed'
        @sale.get('offsetStartAtMoment').isSame(moment(@sale.get('start_at'))).should.be.ok()
        @sale.get('offsetEndAtMoment').isSame(moment(@sale.get('end_at'))).should.be.ok()

  describe '#calculateAuctionState', ->
    before ->
      # moment#unix returns seconds
      # sinon#useFakeTimers accepts milliseconds
      now = moment([2010, 0, 15]).unix() * 1000
      @clock = sinon.useFakeTimers now

    after ->
      @clock.restore()

    it 'returns with the correct state (closed)', ->
      start = moment().subtract(1, 'minutes').format()
      end = moment().subtract(3, 'minutes').format()
      @sale.calculateAuctionState(start, end).should.equal 'closed'

    it 'returns with the correct state (preview)', ->
      start = moment().add(1, 'minutes').format()
      end = moment().add(3, 'minutes').format()
      @sale.calculateAuctionState(start, end).should.equal 'preview'

    it 'returns with the correct state (open)', ->
      start = moment().subtract(1, 'minutes').format()
      end = moment().add(3, 'minutes').format()
      @sale.calculateAuctionState(start, end).should.equal 'open'

    it 'accomdates offsets', ->
      start = moment().subtract(1, 'seconds').format()
      end = moment().add(1, 'seconds').format()
      @sale.calculateAuctionState(start, end, 0).should.equal 'open'
      @sale.calculateAuctionState(start, end, -999).should.equal 'open'
      @sale.calculateAuctionState(start, end, -1000).should.equal 'closed'

  describe '#parse', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()
      @sale = new Sale
        auction_state: 'open' # An incorrect state 'returned from the server'
        start_at: moment().subtract(1, 'minutes').format()
        end_at: moment().subtract(3, 'minutes').format()
      , parse: true

    afterEach ->
      @clock.restore()

    it 'corrects the state', ->
      @sale.get('auction_state').should.equal 'closed'
