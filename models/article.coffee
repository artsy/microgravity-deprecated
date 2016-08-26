_ = require 'underscore'
_s = require 'underscore.string'
Q = require 'bluebird-q'
sd = require('sharify').data
moment = require 'moment'
Backbone = require 'backbone'
Artworks = require '../collections/artworks.coffee'
Section = require './section.coffee'
{ crop, resize } = require '../components/resizer/index.coffee'
{ compactObject } = require './mixins/compact_object.coffee'

module.exports = class Article extends Backbone.Model

  defaults:
    sections: []

  urlRoot: "#{sd.POSITRON_URL}/api/articles"

  href: ->
    "/article/#{@get('slug')}"

  fullHref: ->
    "#{sd.ARTSY_URL}/article/#{@get('slug')}"

  date: (attr = 'published_at') ->
    moment @get(attr)

  formatDate: ->
    @date('published_at').format('MMMM Do')

  related: ->
    return @__related__ if @__related__?
    @__related__ =
      author: new Backbone.Model(@get 'author')

  cropUrlFor: (attr, args...) ->
    crop @get(attr), args...

  authorHref: ->
    if @get('author') then "/#{@get('author').profile_handle}" else @href()

  shareDescription: ->
    (@get('share_description') or @get('thumbnail_title')) + " @artsy"

  fetchRelated: (options) ->
    Articles = require '../collections/articles.coffee'
    dfds = []
    relatedArticles = new Articles()
    calloutArticles = new Articles()
    superArticle = false
    if @get('section_ids')?.length
      dfds.push (section = new Section(id: @get('section_ids')[0])).fetch()
      dfds.push (sectionArticles = new Articles).fetch
        cache: true
        data: section_id: @get('section_ids')[0], published: true
    else
      dfds.push (footerArticles = new Articles).fetch
        cache: true
        data:
          published: true
          featured: true
          tier: 1
          channel_id: sd.ARTSY_EDITORIAL_CHANNEL
          sort: '-published_at'

    # Check if the article is a super article
    if @get('is_super_article')
      superArticle = this
    else
       # Check if the article is IN a super article
      dfds.push (foo = new Articles()).fetch
        data:
          super_article_for: @get('id')
          published: true
        success: (articles) ->
          superArticle = articles?.models[0]

    # Get callout articles
    if @get('sections')?.length
      for sec in @get('sections') when sec.type is 'callout'
        if sec.article
          dfds.push new Article(id: sec.article).fetch
            success: (article) ->
              calloutArticles.add(article)

    Q.allSettled(dfds).then =>
      superArticleDefferreds = if superArticle then superArticle.fetchRelatedArticles(relatedArticles) else []
      Q.allSettled(superArticleDefferreds).then =>
        relatedArticles.orderByIds(superArticle.get('super_article').related_articles) if superArticle and relatedArticles?.length
        footerArticles.remove @ if footerArticles
        sectionArticles.remove @ if sectionArticles
        @set('section', section) if section
        options.success(
          article: this
          footerArticles: footerArticles
          section: section
          sectionArticles: sectionArticles
          superArticle: superArticle
          relatedArticles: relatedArticles
          calloutArticles: calloutArticles
        )

  #
  # Super Article helpers
  fetchRelatedArticles: (relatedArticles) ->
    for id in @get('super_article').related_articles
      new Article(id: id).fetch
        success: (article) =>
          relatedArticles.add article

  toJSONLD: ->
    creator = []
    creator.push @get('author').name if @get('author')
    creator = _.union(creator, _.pluck(@get('contributing_authors'), 'name')) if @get('contributing_authors').length
    compactObject {
      "@context": "http://schema.org"
      "@type": "NewsArticle"
      "headline": @get('thumbnail_title')
      "url": "#{sd.FORCE_URL}" + @href()
      "thumbnailUrl": @get('thumbnail_image')
      "dateCreated": @get('published_at')
      "articleSection": if @get('section') then @get('section').get('title') else "Editorial"
      "creator": creator
      "keywords": @get('tags') if @get('tags').length
    }
