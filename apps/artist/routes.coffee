Artist = require '../../models/artist'
metaphysics = require '../../lib/metaphysics'

query = """
  query artist($id: String!) {
    artist(id: $id) {
      name
      id
      hometown
      years
      biography_blurb(format: HTML) {
        text
        credit
      }
    }
  }

"""

module.exports.index = (req, res, next) ->
  artist = new Artist id: req.params.id
  artist.fetch
    cache: true
    success: ->
      artist.maybeFetchAndSetFeaturedBio =>
        res.locals.sd.ARTIST = artist.toJSON()
        showAuctionLink = artist.get('display_auction_link')
        res.render 'page', artist: artist, sort: req.query?.sort, showAuctionLink: showAuctionLink
    error: res.backboneError

module.exports.biography = (req, res, next) ->
  metaphysics query: query, variables: req.params, req: req
    .then (data) ->
      res.locals.sd.ARTIST = data.artist
      res.render 'biography', artist: data.artist
    .catch next

module.exports.auctionResults = (req, res, next) ->
  artist = new Artist id: req.params.id
  artist.fetch
    error: res.backboneError
    cache: true
    success: ->
      artist.fetchAuctionResults
        data: access_token: req.user?.get('accessToken')
        error: res.backboneError
        cache: true
        success: (results, resp, opts) ->
          totalCount = opts.res?.headers?['x-total-count']
          res.locals.sd.ARTIST = artist.toJSON()
          res.render 'auction_results',
            auctionResults: results.models
            artist: artist
            sort: req.query?.sort
            totalCount: totalCount
