bootstrap = require '../../components/layout/bootstrap.coffee'
$searchBox = null
track = require('../../lib/analytics.coffee').track
track_links = require('../../lib/analytics.coffee').track_links
CurrentUser = require '../../models/current_user.coffee'
module.exports.CURRENT_USER = require('sharify').data.CURRENT_USER

user = null
query = null
clearSearch = (e) ->
  $searchBox.val('')
  $searchBox.focus() unless $(e.target) is $searchBox
  $('#main-header-search-box-cancel').remove()
  false

module.exports.init = ->
  bootstrap()
  user = new CurrentUser(module.exports.CURRENT_USER)

  $searchBox = $('#main-header-search-box')
  query = $searchBox.val()

  track.funnel 'Searched from header, with results', { query: query }

  $searchBox.focus clearSearch

  track_links '#search-page-result-groups a', 'Selected item from search', onTrackLinks

module.exports.onTrackLinks = onTrackLinks = (el) ->
  selected = $(el).attr('href')?.split('/').pop()
  group = $(el).closest('ul')?.prev('.search-page-result-header').text()
  {
    query: query,
    label: "#{group}:#{selected}"
    category: 'UI Interactions'
    page: window?.location.pathname
    noninteraction: false
    user: user?.get('id')
  }