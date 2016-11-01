_ = require 'underscore'
Q = require 'bluebird-q'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Article = require '../../models/article.coffee'
sinon = require 'sinon'
fixtures = require '../helpers/fixtures.coffee'

describe "Article", ->
  beforeEach ->
    @article = new Article fixtures.article

  afterEach ->
    Backbone.sync.restore()

  describe '#fetchRelated', ->
    it 'works for sectionless articles', ->
      article = _.extend {}, fixtures.article,
        id: 'id-1'
        sections: []

      sinon.stub Backbone, 'sync'
        .onCall 0
        .yieldsTo 'success', article
        .returns Q.resolve article

      @article.set 'id', 'article-1'
      @article.is_super_article = false
      @article.sections = []
      @article.fetchRelated success: (data) ->
        data.article.get('id').should.equal 'article-1'

    it 'only fetches section content', ->
      sinon.stub Backbone, 'sync'
        .onCall 0
        .yieldsTo 'success', fixtures.section
        .returns Q.resolve fixtures.section
        .onCall 1
        .yieldsTo 'success', []
        .returns Q.resolve []

      @article.is_super_article = false
      @article.set
        section_ids: ['foo']
        id: 'article-1'
      @article.fetchRelated success: (data) ->
        data.section.get('title').should.equal 'Vennice Biennalez'

    it 'fetches related articles for article in super article', ->
      relatedArticle1 = _.extend {}, fixtures.article,
        id: 'id-1'
        title: 'RelatedArticle 1',
        sections: []
      relatedArticle2 = _.extend {}, fixtures.article,
        id: 'id-2'
        title: 'RelatedArticle 2',
        sections: []
      superArticle = _.extend {}, fixtures.article,
        id: 'id-3'
        title: 'SuperArticle',
        is_super_article: true
        sections: []
        super_article:
          related_articles: ['id-1', 'id-2']

      @article.set
        section_ids: []
        id: 'article-1'

      sinon.stub Backbone, 'sync'
        .onCall 0
        .returns Q.resolve []
        .onCall 1
        .yieldsTo 'success', {results: superArticle}
        .returns Q.resolve {results: superArticle}
        .onCall 2
        .yieldsTo 'success', relatedArticle2
        .returns Q.resolve relatedArticle2
        .onCall 3
        .yieldsTo 'success', relatedArticle1
        .returns Q.resolve relatedArticle1

      @article.fetchRelated success: (data) ->
        data.superArticle.get('title').should.equal 'SuperArticle'
        data.relatedArticles.models[0].get('title').should.equal 'RelatedArticle 1'
        data.relatedArticles.models[1].get('title').should.equal 'RelatedArticle 2'
