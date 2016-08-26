_ = require 'underscore'
jade = require 'jade'
cheerio = require 'cheerio'
path = require 'path'
fs = require 'fs'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'

render = (templateName) ->
  filename = path.resolve __dirname, "../#{templateName}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Artwork bid templates', ->
  beforeEach ->
    @artwork = fabricate 'artwork'
    auction = fabricate 'sale', {
      is_auction: true
      is_open: true
      sale_artwork: fabricate 'sale_artwork', {
        reserve_status: 'reserve_not_met'
        current_bid:
          amount: '$7,000'
        counts:
          bidder_positions: 3
      }
    }
    global.window = {}
    @artwork.auction = auction

  afterEach ->
    delete global.window

  describe 'artwork in open auction', ->

    beforeEach ->
      @artwork.auction.is_open = true

      @html = render('index')(
        artwork: @artwork
        sd: {}
        asset: (->)
      )

      @$ = cheerio.load(@html)

    it 'display artwork current bid, bid counts, reserve status', ->
      @$('.artwork-auction-bid-module__bid-status-amount').text().should.equal '$7,000'
      @$('.artwork-auction-bid-module__bid-status-count').text().should.containEql '3 Bids, Reserve not met'

    it 'displays form with correct action', ->
      @$('.artwork-auction-bid-form.js-artwork-auction-bid-form').attr('action').should.containEql '/auction/whtney-art-party/bid/skull'

    it 'displays an enabled bid button', ->
      @$('.auction-avant-garde-black-button').should.not.containEql 'disabled'
      @$('.auction-avant-garde-black-button').text().should.equal 'Bid'

  describe 'bidder with bidder positions', ->

    beforeEach ->
      @artwork.auction.is_open = true
      @me =  { id: 'my unique id', bidder_positions: [{is_winning: true}] }

      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays user bidder status - highest bid', ->
      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('highest-bid').should.equal true
      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('outbid').should.equal false

    it 'displays user bidder status - highest bid if multiple bidder positions', ->
      @me.bidder_positions = [{is_winning: false}, {is_winning: true}, {is_winning: false}]
      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('highest-bid').should.equal true
      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('outbid').should.equal false

    it 'displays user bidder status - outbid', ->
      me =  { id: 'my unique id', bidder_positions: [{is_winning: false}] }

      @html = render('index')(
        artwork: @artwork
        me: me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('outbid').should.equal true
      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('highest-bid').should.equal false

    it 'displays user bidder status - outbid bid if multiple bidder positions', ->
      @me.bidder_positions = [{is_winning: false}, {is_winning: false}, {is_winning: false}]
      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('highest-bid').should.equal false
      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('outbid').should.equal true

    it 'displays correct bidding amount label with bids', ->
      me =  { id: 'my unique id', bidder_positions: [{is_winning: false}] }

      @html = render('index')(
        artwork: @artwork
        me: me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

      @$('.artwork-auction-bid-module__bid-status-title').text().should.equal 'Current Bid:'

  describe 'bidder with no bidder positions', ->

    beforeEach ->
      @artwork.auction.is_open = true
      @me =  { id: 'my unique id', bidder_positions: [] }

      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays user bidder status', ->

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').should.not.exist

  describe 'ask a specialist', ->

    beforeEach ->
      @artwork.auction.is_open = true

      @html = render('index')(
        artwork: @artwork
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays link to ask a specialist', ->

      @$('.ask-a-specialist').attr('href').should.containEql '/ask_specialist'

    describe 'bidder with no bidder positions', ->
      beforeEach ->
        @artwork.auction.is_open = true
        @me =  { id: 'my unique id', bidder_positions: [ {is_winning: true} ] }

        @html = render('index')(
          artwork: @artwork
          me: @me
          sd: {}
          asset: (->)
          _: _
        )

        @$ = cheerio.load(@html)

      it 'displays user bidder status', ->

        @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('highest-bid').should.equal true
        @$('.user-bid-status-text').text().should.equal 'Highest Bid'

  describe 'bidder with no bidder positions', ->
    beforeEach ->
      @artwork.auction.is_open = true
      @me =  { id: 'my unique id', bidder_positions: [ {is_winning: false} ] }

      @html = render('index')(
        artwork: @artwork
        me: @me
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays user bidder status', ->

      @$('.artwork-auction-bid-module__bid-status__users-bid-status').hasClass('outbid').should.equal true
      @$('.user-bid-status-text').text().should.equal 'Outbid'

  describe 'artwork in a closed auction', ->
    beforeEach ->
      @artwork.auction.is_open = false

      @html = render('index')(
        artwork: @artwork
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays auction closed', ->
      @$('.artwork-auction-bid-module__closed').text().should.equal 'Auction Closed'

  describe 'artwork in auction with zero bids', ->
    beforeEach ->
      @artwork = fabricate 'artwork'
      auction = fabricate 'sale', {
        is_auction: true
        is_open: true
        sale_artwork: fabricate 'sale_artwork', {
          reserve_status: 'reserve_not_met'
          current_bid:
            amount: '$600'
          counts:
            bidder_positions: 0
        }
      }

      @artwork.auction = auction

      @html = render('index')(
        artwork: @artwork
        sd: {}
        asset: (->)
        _: _
      )

      @$ = cheerio.load(@html)

    it 'displays the correct bidding label with zero bids', ->
      @$('.artwork-auction-bid-module__bid-status-title').text().should.equal 'Starting Bid:'


    it 'do not display number of bids', ->
      @$('.artwork-auction-bid-module__bid-status-count').text().should.equal 'Reserve not met'
