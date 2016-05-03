{$} = require 'atom-space-pen-views'
SparkStub = require('particle-dev-spec-stubs').spark
CloudVariablesView = require '../lib/cloud-variables-view'
spark = require 'spark'
SettingsHelper = null

describe 'Cloud Variables View', ->
  activationPromise = null
  originalProfile = null
  particleDev = null
  cloudVariables = null
  cloudVariablesView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    activationPromise = atom.packages.activatePackage('particle-dev-cloud-variables').then ({mainModule}) ->
      cloudVariables = mainModule

    particleDevPromise = atom.packages.activatePackage('particle-dev').then ({mainModule}) ->
      particleDev = mainModule
      SettingsHelper = particleDev.SettingsHelper

    waitsForPromise ->
      activationPromise

    waitsForPromise ->
      particleDevPromise

    runs ->
      originalProfile = SettingsHelper.getProfile()
      # For tests not to mess up our profile, we have to switch to test one...
      SettingsHelper.setProfile 'particle-dev-test'

  afterEach ->
    SettingsHelper.setProfile originalProfile

  describe '', ->
    beforeEach ->
      SettingsHelper.setCredentials 'foo@bar.baz', '0123456789abcdef0123456789abcdef'
      SettingsHelper.setCurrentCore '0123456789abcdef0123456789abcdef', 'Foo'
      SettingsHelper.setLocal 'variables', {foo: 'int32'}

    afterEach ->
      SettingsHelper.clearCurrentCore()
      SettingsHelper.clearCredentials()
      SettingsHelper.setLocal 'variables', {}

    it 'checks listing variables', ->
      SparkStub.stubNoResolve spark, 'getVariable'

      cloudVariablesView = new CloudVariablesView(null, particleDev)
      cloudVariablesView.setup()
      spyOn cloudVariablesView, 'refreshVariable'
      SparkStub.stubSuccess spark, 'getVariable'

      body = cloudVariablesView.find('#particle-dev-cloud-variables')

      expect(body.find('table')).toExist()

      expect(body.find('table > thead')).toExist()
      expect(body.find('table > thead > tr')).toExist()
      expect(body.find('table > thead > tr > th:eq(0)').text()).toEqual('Name')
      expect(body.find('table > thead > tr > th:eq(1)').text()).toEqual('Type')
      expect(body.find('table > thead > tr > th:eq(2)').text()).toEqual('Value')
      expect(body.find('table > thead > tr > th:eq(3)').text()).toEqual('Refresh')

      expect(body.find('table > tbody')).toExist()
      expect(body.find('table > tbody > tr')).toExist()
      expect(body.find('table > tbody > tr').length).toEqual(1)
      expect(body.find('table > tbody > tr:eq(0) > td:eq(0)').text()).toEqual('foo')
      expect(body.find('table > tbody > tr:eq(0) > td:eq(1)').text()).toEqual('int32')
      expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').text()).toEqual('')
      expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(true)
      expect(body.find('table > tbody > tr:eq(0) > td:eq(3) > button')).toExist()
      expect(body.find('table > tbody > tr:eq(0) > td:eq(3) > button').hasClass('icon-sync')).toBe(true)

      expect(body.find('table > tbody > tr:eq(0) > td:eq(4) > button')).toExist()
      expect(body.find('table > tbody > tr:eq(0) > td:eq(4) > button').hasClass('icon-eye')).toBe(true)

      # Test refresh button
      body.find('table > tbody > tr:eq(0) > td:eq(3) > button').click()
      expect(cloudVariablesView.refreshVariable).toHaveBeenCalled()
      expect(cloudVariablesView.refreshVariable).toHaveBeenCalledWith('foo')
      jasmine.unspy cloudVariablesView, 'refreshVariable'

    it 'tests refreshing', ->
      SparkStub.stubSuccess spark, 'getVariable'
      cloudVariablesView = new CloudVariablesView(null, particleDev)
      cloudVariablesView.setup()
      body = cloudVariablesView.find('#particle-dev-cloud-variables')

      waitsFor ->
        body.find('table > tbody > tr:eq(0) > td:eq(2)').text() == '1'

      runs ->
        expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(false)

    it 'checks event hooks', ->
      SparkStub.stubSuccess spark, 'getVariable'
      cloudVariablesView = new CloudVariablesView(null, particleDev)
      cloudVariablesView.setup()

      # Tests particle-dev:update-core-status
      spyOn cloudVariablesView, 'listVariables'
      spyOn cloudVariablesView, 'clearWatchers'
      atom.commands.dispatch workspaceElement, 'particle-dev:core-status-updated'
      expect(cloudVariablesView.listVariables).toHaveBeenCalled()
      expect(cloudVariablesView.clearWatchers).toHaveBeenCalled()
      jasmine.unspy cloudVariablesView, 'listVariables'
      jasmine.unspy cloudVariablesView, 'clearWatchers'

      # Tests particle-dev:logout
      SettingsHelper.clearCredentials()
      spyOn cloudVariablesView, 'close'
      spyOn cloudVariablesView, 'clearWatchers'
      atom.commands.dispatch workspaceElement, 'particle-dev:logout'
      expect(cloudVariablesView.close).toHaveBeenCalled()
      expect(cloudVariablesView.clearWatchers).toHaveBeenCalled()
      jasmine.unspy cloudVariablesView, 'close'
      jasmine.unspy cloudVariablesView, 'clearWatchers'

    it 'check watching variable', ->
      SparkStub.stubSuccess spark, 'getVariable'
      cloudVariablesView = new CloudVariablesView(null, particleDev)
      cloudVariablesView.setup()

      row = cloudVariablesView.find('#particle-dev-cloud-variables table > tbody > tr:eq(0)')

      watchButton = row.find('td:eq(4) > button')
      refreshButton = row.find('td:eq(3) > button')

      expect(refreshButton.attr('disabled')).not.toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(false)
      expect(Object.keys(cloudVariablesView.watchers).length).toEqual(0)

      jasmine.Clock.useMock()
      spyOn cloudVariablesView, 'refreshVariable'

      watchButton.click()

      expect(refreshButton.attr('disabled')).toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(true)
      expect(Object.keys(cloudVariablesView.watchers).length).toEqual(1)
      expect(Object.keys(cloudVariablesView.watchers)).toEqual(['foo'])
      expect(cloudVariablesView.refreshVariable).not.toHaveBeenCalled()
      watcher = cloudVariablesView.watchers['foo']

      jasmine.Clock.tick(5001)

      expect(cloudVariablesView.refreshVariable).toHaveBeenCalled()
      expect(cloudVariablesView.refreshVariable).toHaveBeenCalledWith('foo')

      spyOn window, 'clearInterval'

      expect(window.clearInterval).not.toHaveBeenCalled()

      watchButton.click()

      expect(refreshButton.attr('disabled')).not.toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(false)
      expect(Object.keys(cloudVariablesView.watchers).length).toEqual(0)
      expect(window.clearInterval).toHaveBeenCalled()
      expect(window.clearInterval).toHaveBeenCalledWith(watcher)

      # TODO: Test clearing all watchers

      jasmine.unspy window, 'clearInterval'
      jasmine.unspy cloudVariablesView, 'refreshVariable'

    it 'checks clearing watchers', ->
      cloudVariablesView = new CloudVariablesView(null, particleDev)
      cloudVariablesView.setup()

      cloudVariablesView.watchers['foo'] = 'bar'
      spyOn window, 'clearInterval'
      expect(window.clearInterval).not.toHaveBeenCalled()

      expect(Object.keys(cloudVariablesView.watchers).length).toEqual(1)
      cloudVariablesView.clearWatchers()

      expect(window.clearInterval).toHaveBeenCalled()
      expect(window.clearInterval).toHaveBeenCalledWith('bar')
      expect(Object.keys(cloudVariablesView.watchers).length).toEqual(0)

      jasmine.unspy window, 'clearInterval'
