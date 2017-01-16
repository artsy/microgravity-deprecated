require 'jquery'
require('backbone').$ = $
articleIndex = require '../apps/articles/client/articles.coffee'
articleShowAndIndex = require '../apps/articles/client/index.coffee'

$ ->
  articleShowAndIndex()

  if location.pathname is '/articles'
    articleIndex.init()
