_ = require 'underscore'
_s = require 'underscore.string'
sd = require('sharify').data
Backbone = require 'backbone'
moment = require 'moment'
{ crop, fill } = require '../components/resizer/index.coffee'

module.exports = class GooogleSearchResult extends Backbone.Model

  facebookAppNamespace: "artsyinc"

  initialize: (options) ->
    @set
      id: @getId()
      display: @formatTitle(@get('title'))
      image_url: @imageUrl()
      display_model: @displayModel()
      location: @href()

    @set
      about: @about(@get('snippet'))

  # Gets the id out of the url
  getId: ->
    id = @href().split('?')[0]
    if id.split('/').length > 2
      id = id.split('/')[2]
    id

  href: ->
    @get('link')
      .replace(/http(s?):\/\/(w{3}\.)?artsy.net/, '')
      .replace('#!', '')

  imageUrl: ->
    return "" if @get('display_model') is 'artwork'
    src = @get('pagemap')?.cse_thumbnail?[0].src or @get('pagemap')?.cse_image?[0].src
    crop src, width: 100, height: 100

  ogType: ->
    return @get('ogType') if @get('ogType')
    ogType =
      if @href().indexOf('/show/') > -1
        # Shows have the og:type 'article'
        'show'
      else if profileType = @get('pagemap')?.metatags?[0]?['profile:type']
        @set baseType: @get('pagemap')?.metatags[0]?['og:type']?.replace("#{@facebookAppNamespace}:", "")
        profileType
      else
        @get('pagemap')?.metatags?[0]?['og:type']?.replace("#{@facebookAppNamespace}:", "")
    @set
      ogType: ogType
    ogType

  about: (text) ->
    if @get('display_model') is 'article'
      text
    else if @get('display_model') is 'Fair'
      @formatEventAbout('Art fair')
    else
      @get('pagemap')?.metatags?[0]?['og:description']

  formatTitle: (title) ->
    _s.trim(
      if @ogType() is 'artwork'
        "#{title.split(' | ')[0]}, #{title.split(' | ')[1]}"
      else
        title?.split('|')[0]
    )

  displayModel: ->
    if @ogType() is 'website'
      false
    else if @ogType() is 'gene'
      'category'
    else
      @ogType()

  formatEventAbout: (title) ->
    metatags = @get('pagemap')?.metatags?[0]

    if startTime = metatags['og:start_time']
      formattedStartTime = moment(startTime).format("MMMM Do")
    if endTime = metatags['og:end_time']
      formattedEndTime = moment(endTime).format("MMMM Do, YYYY")

    location = metatags['og:location']

    if formattedStartTime and formattedEndTime and location
      "#{title} running from #{formattedStartTime} to #{formattedEndTime} at #{location}"
    else
      metatags['og:description']
