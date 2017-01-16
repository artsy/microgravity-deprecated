_ = require 'underscore'
sinon = require 'sinon'
rewire = require 'rewire'
routes = rewire '../routes'
Backbone = require 'backbone'
fixtures = require '../../../test/helpers/fixtures'
moment = require 'moment'
Articles = require '../../../collections/articles'
Article = require '../../../models/article'
request = require 'superagent'

describe 'Article routes', ->
  beforeEach ->
    @req = params: id: 'foobar'
    @res =
      render: sinon.stub()
      locals:
        sd: {}
    @next = sinon.stub()
    sinon.stub Backbone, 'sync'
    routes.__set__ 'sailthru', apiGet: sinon.stub().yields('error')

  afterEach ->
    Backbone.sync.restore()

  describe '#article', ->

    it 'fetches and redirects partner articles', (done) ->
      article = _.extend _.clone(fixtures.article), id: 'foobar'
      routes.article @req, @res, @next
      Backbone.sync.args[0][1].url().should.containEql 'api/articles/foobar'
      Backbone.sync.args[0][2].success article
      Backbone.sync.args[1][2].data.featured.should.be.ok()
      Backbone.sync.args[1][2].success()
      _.defer => _.defer =>
        @res.render.args[0][0].should.equal 'article'
        @res.render.args[0][1].article.id.should.equal 'foobar'
        done()

    it 'fetches and redirects fair articles', (done) ->
      article = _.extend _.clone(fixtures.article), id: 'foobar'
      routes.article @req, @res, @next
      Backbone.sync.args[0][1].url().should.containEql 'api/articles/foobar'
      Backbone.sync.args[0][2].success article
      Backbone.sync.args[1][2].data.featured.should.be.ok()
      Backbone.sync.args[1][2].success()
      _.defer => _.defer =>
        @res.render.args[0][0].should.equal 'article'
        @res.render.args[0][1].article.id.should.equal 'foobar'
        done()

    it 'nexts regular articles', (done) ->
      article = _.extend _.clone(fixtures.article), id: 'foobar'
      routes.article @req, @res, @next
      Backbone.sync.args[0][1].url().should.containEql 'api/articles/foobar'
      Backbone.sync.args[0][2].success article
      Backbone.sync.args[1][2].data.featured.should.be.ok()
      Backbone.sync.args[1][2].success()
      _.defer => _.defer =>
        @res.render.args[0][0].should.equal 'article'
        @res.render.args[0][1].article.id.should.equal 'foobar'
        done()

  describe '#section', ->

    it 'renders the section with its articles', ->
      section = _.extend _.clone(fixtures.section), slug: 'foo'
      @req.params.slug = 'foo'
      routes.section @req, @res, @next
      Backbone.sync.args[0][2].success section
      Backbone.sync.args[1][2].data.section_id.should.equal section.id
      Backbone.sync.args[1][2].success fixtures.articles
      @res.render.args[0][0].should.equal 'section'
      @res.render.args[0][1].featuredSection.get('title').should.equal section.title

    it 'nexts for an error b/c it uses a root url that should be passed on', ->
      routes.section @req, @res, @next
      Backbone.sync.args[0][2].error()
      @next.called.should.be.ok()

describe "#articles", ->

  beforeEach ->
    routes.__set__ 'sailthru', apiGet: sinon.stub().yields('error')
    sinon.stub request, 'post'
      .returns
        send: sinon.stub().returns
          end: sinon.stub().yields(null, body: data: articles: [fixtures.article])
    @req = { params: {} }
    @res = { render: sinon.stub(), locals: { sd: {} }, redirect: sinon.stub() }
    @next = sinon.stub()

  afterEach ->
    request.post.restore()

  it 'fetches a collection of articles and renders the list', (done) ->
    routes.articles @req, @res, @next
    @res.render.args[0][0].should.equal 'articles'
    @res.render.args[0][1].articles[0].thumbnail_title.should.containEql 'Top Ten Booths at miart 2014'
    done()
