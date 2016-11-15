_ = require 'underscore'
jade = require 'jade'
path = require 'path'
fs = require 'fs'

render = (templateName) ->
  filename = path.resolve __dirname, "../templates/#{templateName}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Main', ->

  it 'renders a marketing CTA if in a configured path', ->
    render('main')(
      _: _
      sd:
        AP: {}
        MARKETING_SIGNUP_MODAL_PATHS: '/foo,/bar'
        CURRENT_PATH: '/foo'
    ).should.containEql 'marketing-signup-modal'
