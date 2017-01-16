Backbone = require 'backbone'
_ = require 'underscore'
sd = require('sharify').data
Article = require '../../../models/article.coffee'
Articles = require '../../../collections/articles.coffee'
SlideshowsView = require './slideshows.coffee'
Partner = require '../../../models/partner.coffee'
partnerBreadcrumbTemplate = -> require('../templates/partner_breadcrumb.jade') arguments...

module.exports = class ArticleView extends Backbone.View

  events:
    'click .article-video-play-button' : 'clickPlay'

  initialize: ->
    @article = new Article sd.ARTICLE
    @setupPartnerBreadcrumb() if @article.get('partner_channel_id')
    new SlideshowsView

  setupPartnerBreadcrumb: =>
    new Partner(id: @article.get('partner_ids')?[0]).fetch
      success: (partner) =>
        @$('#article-body-container').addClass('partner').prepend partnerBreadcrumbTemplate
          name: partner.get('name')
          href: "/" + partner.get('default_profile_id')

  clickPlay: (event) ->
    $cover = $(event.currentTarget).parent()
    $iframe = $cover.next('.article-section-video').find('iframe')
    $newIframe = $iframe.clone().attr('src', $iframe.attr('src') + '&autoplay=1')
    $iframe.replaceWith $newIframe
    $cover.remove()
