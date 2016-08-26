_ = require 'underscore'
sd = require('sharify').data
CTABarView = require '../../../components/cta_bar/view.coffee'
bootstrap = require '../../../components/layout/bootstrap.coffee'

module.exports = ->
  bootstrap()

  # Handle Artsy gallery team insights
  if (sd.SECTION?.id is '55550be07b8a750300db8430' or _.contains(sd.ARTICLE?.section_ids,'55550be07b8a750300db8430')) and sd.MAILCHIMP_SUBSCRIBED is false

    # Show input form
    $('.articles-insights-section').show()
    # CTA Bar
    ctaBarView = new CTABarView
      headline: 'Get Gallery Insights in your inbox'
      mode: 'email'
      name: 'gallery-insights-signup'
      persist: true
      email: sd.CURRENT_USER?.email or ''
    unless ctaBarView.previouslyDismissed()
      $('body').append ctaBarView.render().$el
      $('.articles-section__feed').waypoint (direction) ->
        ctaBarView.transitionIn() if direction is 'down'
      $('.article-footer-next').waypoint (direction) ->
        ctaBarView.transitionIn() if direction is 'down'

    # Subscribe click
    $('.js-articles-insights-subscribe').click (e)->
      $(e.currentTarget).addClass 'is-loading'
      $.ajax
        type: 'POST'
        url: '/gallery-insights/form'
        data:
          email: $(e.currentTarget).prev('input').val()
          fname: sd.CURRENT_USER?.name?.split(' ')[0] or= ''
          lname: sd.CURRENT_USER?.name?.split(' ')[1] or= ''
        error: (xhr) ->
          $(e.currentTarget).removeClass 'is-loading'
          $('.articles-insights-header').text(xhr.responseText)
          $('.cta-bar-header h2').text(xhr.responseText)
        success: (res) =>
          $(e.currentTarget).removeClass 'is-loading'
          $('.cta-bar-header h2').text ''
          $('.articles-insights-call').fadeOut()
          $('.articles-insights-thanks').fadeIn()
          $('.cta-bar-email').fadeOut( ->
            $('.cta-bar-thanks').fadeIn()
          )
          setTimeout( ->
            ctaBarView.close()
          ,2000)

    $('.js-articles-insights-click').click (e)->
      $('.cta-bar-email-input').show()
      $(e.currentTarget).hide()
