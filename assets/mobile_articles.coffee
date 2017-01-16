require 'jquery'
require('backbone').$ = $
articleIndex = require '../apps/articles/client/articles.coffee'

$ ->
  if location.pathname is '/articles'
    articleIndex.init()
