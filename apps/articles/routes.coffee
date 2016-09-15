_ = require 'underscore'
Q = require 'bluebird-q'
{ MAILCHIMP_KEY, SAILTHRU_KEY, SAILTHRU_SECRET, SAILTHRU_MASTER_LIST } = require '../../config'
sd = require('sharify').data
request = require 'superagent'
Article = require '../../models/article'
Articles = require '../../collections/articles'
Section = require '../../models/section'
Sections = require '../../collections/sections'
embed = require 'embed-video'
{ stringifyJSONForWeb } = require '../../components/util/json.coffee'
sailthru = require('sailthru-client').createSailthruClient(SAILTHRU_KEY,SAILTHRU_SECRET)

@article = (req, res, next) ->
  article = new Article id: req.params.id
  article.fetch
    cache: true
    error: -> next()
    success: =>
      article.fetchRelated
        success: (data) ->
          res.locals.sd.ARTICLE = article
          res.locals.sd.RELATED_ARTICLES = data.relatedArticles?.toJSON()
          if article.get('partner_channel_id')
            return next()
          email = res.locals.sd.CURRENT_USER?.email
          subscribedToGI email, article.get('section_ids')?[0], (cb) ->
            res.locals.sd.MAILCHIMP_SUBSCRIBED = cb
          subscribedToEditorial email, (err, subscribed) ->
            res.locals.sd.SUBSCRIBED_TO_EDITORIAL = subscribed
          # Only Artsy Editorial and non super/subsuper articles can have an infinite scroll
          if data.relatedArticles?.length > 0
            res.locals.sd.INFINITE_SCROLL = false
          else if data.article.get('channel_id') isnt sd.ARTSY_EDITORIAL_CHANNEL
            res.locals.sd.INFINITE_SCROLL = false
          else
            res.locals.sd.INFINITE_SCROLL = true

          res.render 'article',
            article: article
            footerArticles: data.footerArticles if data.footerArticles
            featuredSection: data.section
            featuredSectionArticles: data.sectionArticles if data.section
            relatedArticles: data.relatedArticles
            calloutArticles: data.calloutArticles
            superArticle: data.superArticle
            embed: embed
            jsonLD: stringifyJSONForWeb(article.toJSONLD())
            videoOptions: { query: { title: 0, portrait: 0, badge: 0, byline: 0, showinfo: 0, rel: 0, controls: 2, modestbranding: 1, iv_load_policy: 3, color: "E5E5E5" } }
            lushSignup: true

@redirectPost = (req, res, next) ->
  res.redirect 301, req.url.replace 'post', 'article'

@section = (req, res, next) ->
  new Section(id: req.params.slug).fetch
    error: -> next()
    success: (section) ->
      return next() unless req.params.slug is section.get('slug')
      new Articles().fetch
        data: section_id: section.get('id'), published: true, limit: 100, sort: '-published_at'
        error: res.backboneError
        success: (articles) ->
          res.locals.sd.SECTION = section
          email = res.locals.sd.CURRENT_USER?.email
          subscribedToGI email, section.get('id'), (cb) ->
            res.locals.sd.MAILCHIMP_SUBSCRIBED = cb
            res.render 'section', featuredSection: section, articles: articles

@articles = (req, res, next) ->
  Q.allSettled([
    (sections = new Sections).fetch(data: featured: true)
    (articles = new Articles).fetch(
      data:
        published: true
        limit: 10
        sort: '-published_at'
        featured: true
    )
  ]).fail(next).then =>
    email = res.locals.sd.CURRENT_USER?.email
    subscribedToEditorial email, (err, subscribed) ->
      res.locals.sd.SUBSCRIBED_TO_EDITORIAL = subscribed

      res.locals.sd.ARTICLES = articles.toJSON()
      section = sections.running()[0]
      res.render 'articles',
        featuredSection: section
        articles: articles.models

@form = (req, res, next) ->
  request.post('https://us1.api.mailchimp.com/2.0/lists/subscribe')
    .send(
      apikey: MAILCHIMP_KEY
      id: sd.GALLERY_INSIGHTS_LIST
      email: email: req.body.email
      send_welcome: true
      merge_vars:
        MMERGE1: req.body.fname
        MMERGE2: req.body.lname
        MMERGE3: 'Opt-in (artsy.net)'
      double_optin: false
      send_welcome: true
    ).end (err, response) ->
      if (response.ok)
        res.send req.body
      else
        res.send(response.status, response.body.error)

subscribedToGI = (email, sectionId, callback) ->
  if email and sectionId is '55550be07b8a750300db8430'
    request.get('https://us1.api.mailchimp.com/2.0/lists/member-info')
      .query(
        apikey: MAILCHIMP_KEY
        id: sd.GALLERY_INSIGHTS_LIST
      ).query("emails[0][email]=#{email}").end (err, response) ->
        callback response.body.success_count is 1
  else
    callback false

subscribedToEditorial = (email, cb) ->
  sailthru.apiGet 'user', { id: email }, (err, response) ->
    return cb err, false if err
    cb null, response.vars?.receive_editorial_email

@editorialForm = (req, res, next) ->
  sailthru.apiPost 'user',
    id: req.body.email
    lists:
      "#{SAILTHRU_MASTER_LIST}": 1
    name: req.body.name
    vars:
      source: 'editorial'
      receive_editorial_email: true
      email_frequency: 'daily'
  , (err, response) ->
    if response.ok
      res.send req.body
    else
      res.status(500).send(response.errormsg)
