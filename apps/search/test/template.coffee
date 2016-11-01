benv = require 'benv'
_ = require 'underscore'
jade = require 'jade'
path = require 'path'
fs = require 'fs'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
SearchResults = require '../../../collections/google_search_results'
SearchResult = require '../../../models/google_search_result'
sinon = require 'sinon'

{ resolve } = require 'path'

describe 'Search results template', ->
  before (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      sinon.stub Backbone, 'sync'
      done()

  after ->
    benv.teardown()
    Backbone.sync.restore()

  beforeEach ->
    @search = new SearchResults

  describe 'No results', ->
    beforeEach (done) ->
      @template = benv.render(resolve(__dirname, '../template.jade'), {
        sd: {}
        results: []
        mainHeaderSearchBoxValue: 'foobar'
        sd: {}
      }, =>
        done()
      )

    it 'displays a message to the user that nothing can be found', ->
      $('body').html().should.containEql 'Nothing found'

  describe 'Has results', ->
    beforeEach (done) ->
      @artworks = _.times 2, (i)->
        new SearchResult({
          link: 'https://artsy.net/artwork/cool-artwork' + i
          title: "Artwork Title | Artist | Artsy"
          snippet: 'cool artwork snippet'
          pagemap:
            metatags: [{'og:type': 'artwork', 'og:description': 'artwork description'}]
            cse_thumbnail: [{ src: 'imgurl' }]
        })
      @artists = _.times 3, (i) ->
        new SearchResult({
          link: 'https://artsy.net/artist/cool-artist' + i
          title: "Artist Name | Artsy"
          snippet: 'cool artist snippet'
          pagemap:
            metatags: [{'og:type': 'artist', 'og:description': 'artist description'}]
            cse_thumbnail: [{ src: 'imgurl' }]
        })

      @search.add @artworks
      @search.add @artists

      @template = benv.render(resolve(__dirname, '../template.jade'), {
        sd: {}
        results: @search.models
        mainHeaderSearchBoxValue: 'foobar'
        sd: {}
      }, =>
        done()
      )

    it 'renders the search results', ->
      $('.search-result').length.should.equal 5
