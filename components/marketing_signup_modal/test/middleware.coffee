sinon = require 'sinon'
middleware = require '../middleware'

describe 'showMarketingSignupModal', ->
  beforeEach ->
    @req = {}
    @res =
      locals:
        sd:
          APP_URL: 'http://www.artsy.net'
          MARKETING_SIGNUP_MODAL_PATHS: '/foo,/bar'
    @next = sinon.stub()

  it 'shows the modal if coming from outside artsy', ->
    @req.path = '/foo'
    @req.get = sinon.stub().returns 'google.com'
    middleware @req, @res, @next
    @res.locals.showMarketingSignupModal.should.be.ok()

  it 'does not show the modal if coming from artsy', ->
    @req.path = '/foo'
    @req.get = sinon.stub().returns 'artsy.net'
    middleware @req, @res, @next
    (@res.locals.showMarketingSignupModal?).should.not.be.ok()

  it 'does not show the modal if not in the right path', ->
    @req.path = '/baz'
    @req.get = sinon.stub().returns 'google.com'
    middleware @req, @res, @next
    (@res.locals.showMarketingSignupModal?).should.not.be.ok()

  it 'does not show the modal if logged in', ->
    @req.user = name: 'Andy'
    @req.path = '/foo'
    @req.get = sinon.stub().returns 'google.com'
    middleware @req, @res, @next
    (@res.locals.showMarketingSignupModal?).should.not.be.ok()
