Page = require '../../models/page'
{ ARTSY_URL } = require '../../config'

@vanityUrl = (id) ->
  (req, res) ->
    new Page(id: id).fetch
      success: (page) ->
        res.render 'template', page: page
      error: res.backboneError

@index = (req, res) ->
  new Page(id: req.params.id).fetch
    success: (page) -> res.render 'template', page: page
    error: res.backboneError
