_ = require 'underscore'
Backbone = require 'backbone'
sd = require('sharify').data
User = require '../../models/user'
{ parse } = require 'url'
qs = require 'querystring'
{ API_URL } = require '../../config'
sanitizeRedirect = require '../../components/sanitize_redirect'

@login = (req, res) ->
  url = req.body['redirect-to'] or
    req.query['redirect-to'] or
    req.param('redirect_uri') or
    req.get('Referrer') or
    '/'

  locals =
    action: req.query?.action or req.session?.action
    redirectTo: sanitizeRedirect(url)
  if req.query.action
    locals.action = req.query.action
    res.render 'call_to_action', locals
  else
    res.render 'login', action: true, redirectTo: sanitizeRedirect(url)

@forgotPassword = (req, res) ->
  res.render 'forgot_password'

@submitForgotPassword = (req, res, next) ->
  new Backbone.Model().save null,
    url: "#{sd.API_URL}/api/v1/users/send_reset_password_instructions?email=#{req.body.email}"
    success: ->
      res.render 'forgot_password_confirmation'
    error: (m, response) ->
      res.render 'forgot_password', error: response.body.error

@resetPassword = (req, res) ->
  res.render 'reset_password'

@signUp = (req, res) ->
  req.session.signupReferrer ?= req.query['redirect-to'] or req.get('Referrer')
  req.session.action ?= req.query.action
  locals =
    redirect: sanitizeRedirect(req.body['redirect-to'] or req.session.signupReferrer or '/')
    redirectTo: sanitizeRedirect(req.query['redirect-to'] or '/personalize/collect')
    action: req.query.action or req.session.action
    error: err?.body.error
    prefill: req.query.prefill
  if req.query.action
    locals.action = req.query.action
    res.render 'call_to_action', locals
  else if req.query.email
    res.render 'signup_email', locals
  else
    res.render 'signup', locals

@twitterLastStep = (req, res) ->
  res.render 'twitter_email'
