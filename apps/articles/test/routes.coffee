_ = require 'underscore'
sinon = require 'sinon'
routes = require '../routes'
Backbone = require 'backbone'
fixtures = require '../../../test/helpers/fixtures'
moment = require 'moment'
Articles = require '../../../collections/articles'
Article = require '../../../models/article'

describe 'Article routes', ->
  beforeEach ->
    @req = params: id: 'foobar'
    @res =
      render: sinon.stub()
      locals:
        sd: {}
    @next = sinon.stub()
    sinon.stub Backbone, 'sync'

  afterEach ->
    Backbone.sync.restore()

  describe '#article', ->

    it 'fetches and renders the article page', (done) ->
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

    it.only 'fetches and render super articles', (done) ->
      article = _.extend _.clone(fixtures.article), id: 'foobar', is_super_article: true, super_article: related_articles: ['related-1']
      relatedArticle = _.extend _.clone(fixtures.article), id: 'related-1'
      routes.article @req, @res, @next
      Backbone.sync.args[0][1].url().should.containEql 'api/articles/foobar'
      Backbone.sync.args[0][2].success article
      Backbone.sync.args[1][2].data.featured.should.be.ok()
      Backbone.sync.args[1][2].success()
      _.defer => _.defer =>
        Backbone.sync.args[2][1].url().should.containEql 'api/articles/related-1'
        Backbone.sync.args[2][2].success relatedArticle
        _.defer => _.defer =>
          @res.render.args[0][0].should.equal 'article'
          @res.render.args[0][1].article.id.should.equal 'foobar'
          @res.render.args[0][1].relatedArticles.models[0].id.should.equal 'related-1'
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
    sinon.stub Backbone, 'sync'
    @req = { params: {} }
    @res = { render: sinon.stub(), locals: { sd: {} }, redirect: sinon.stub() }
    @next = sinon.stub()

  afterEach ->
    Backbone.sync.restore()

  it 'gets the running section and renders the proper template', (done) ->
    routes.articles @req, @res, @next
    section = _.extend(_.clone(fixtures.section), {
      title: 'Foo Bar'
      start_at: moment().subtract(1, 'days')
      end_at: moment().add(1, 'days')
    })

    Backbone.sync.args[0][2].success results: [section]
    Backbone.sync.args[1][2].success()

    _.defer => _.defer =>
      @res.render.args[0][0].should.equal 'articles'
      @res.render.args[0][1].featuredSection.get('title').should.equal 'Foo Bar'
      done()
