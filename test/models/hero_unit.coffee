HeroUnit = require '../../models/hero_unit'
{ fabricate } = require 'antigravity'

describe 'HeroUnit', ->

  beforeEach ->
    @heroUnit = new HeroUnit fabricate 'site_hero_unit'

  describe '#cssClass', ->

    it 'namespaces some classes based off attrs', ->
      @heroUnit.set mobile_menu_color_class: 'black'
      @heroUnit.cssClass().should.containEql 'home-page-hero-unit-black'
