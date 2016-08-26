_ = require 'underscore'
Backbone = require 'backbone'
Cookies = require '../cookies/index.coffee'
template = -> require('./template.jade') arguments...

module.exports = class CTABarView extends Backbone.View

  className: 'cta-bar'

  transitionLength: 500

  events:
    'click .cta-bar-defer': 'close'
    'click .cta-bar-button': 'signUp'
    'submit .cta-bar-form': 'submit'

  defaults:
    name: 'cta_bar'
    mode: 'email'
    persist: true

  initialize: (options = {}) ->
    { @headline, @mode, @name, @persist, @modalOptions, @email } = _.defaults options, @defaults

  previouslyDismissed: ->
    @persist and Cookies.get(@name)?

  logDimissal: ->
    if @persist
      Cookies.set @name, 1, expires: 31536000

  __transition__: (state, cb) ->
    _.defer =>
      @$el.attr 'data-state', state
      _.delay(cb, @transitionLength) if cb?
    this

  transitionIn: (cb) ->
    @__transition__ 'in', cb

  transitionOut: (cb) ->
    @__transition__ 'out', cb

  render: ->
    @$el.html template
      headline: @headline
      mode: @mode
      email: @email
    this

  close: (e) ->
    e?.preventDefault()
    @logDimissal()
    @transitionOut =>
      @remove()
