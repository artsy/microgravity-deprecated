benv = require 'benv'
rewire = require 'rewire'

describe 'AppBanner', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      @AppBanner = rewire '../app_banner'
      $('body').html (@$content = $('<div id="content"></div>'))
      done()

  after ->
    benv.teardown()

  beforeEach ->
    @appBanner = new @AppBanner @$content

  it 'inserts the app banner before the passed in element', ->
    $('body').html().should.containEql 'Artsy for iPhone™'
    $('.app-banner').siblings().attr('id').should.equal 'content'

  describe '#shouldDisplay', ->
    describe 'has not seen, is iOS', ->
      beforeEach ->
        @UA = @AppBanner.__get__ 'USER_AGENT'
        @AppBanner.__set__ 'USER_AGENT', '(Chrome)'

      afterEach ->
        @AppBanner.__set__ 'USER_AGENT', @UA

      it 'should return true', ->
        @AppBanner.shouldDisplay().should.be.true()

      describe 'is also Eigen', ->
        beforeEach ->
          @UA = @AppBanner.__get__ 'USER_AGENT'
          @AppBanner.__set__ 'USER_AGENT', 'Something something / Artsy-Mobile / I have no idea what the real user agent is'

        afterEach ->
          @AppBanner.__set__ 'USER_AGENT', @UA

        it 'returns false if the user agent is that of Eigen', ->
          @AppBanner.shouldDisplay().should.be.false()
