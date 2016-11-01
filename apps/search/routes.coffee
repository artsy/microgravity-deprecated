GoogleSearchResults = require '../../collections/google_search_results'
removeDiacritics = require('diacritics').remove

module.exports.index = (req, res, next) ->
  return res.redirect('/') unless req.query.term

  term = removeDiacritics req.query.term
  res.locals.sd.term = term

  results = new GoogleSearchResults

  results.fetch(data: q: term)
    .then ->
      res.locals.sd.RESULTS = results.toJSON()
      res.render 'template',
        mainHeaderSearchBoxValue: term
        referrer: req.query.referrer
        results: results.moveMatchResultsToTop(term)
    .catch next
    .done()
