_ = require 'underscore'

module.exports = (req, res, next) ->
  sd = res.locals.sd
  slug = req.query['m-id']
  modalData = _.findWhere(sd.MARKETING_SIGNUP_MODALS, { slug: slug })

  if modalData
    sd.MARKETING_SIGNUP_MODAL_IMG = modalData.image
    sd.MARKETING_SIGNUP_MODAL_COPY = modalData.copy
    sd.MARKETING_SIGNUP_MODAL_SLUG = modalData.slug
    sd.MARKETING_SIGNUP_MODAL_PHOTO_CREDIT = modalData.photoCredit

  loggedOut = not req.user?

  res.locals.showMarketingSignupModal = true if loggedOut and modalData?
  next()
