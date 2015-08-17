{$} = require 'atom-space-pen-views'
SparkStub = require('particle-dev-spec-stubs').spark
SparkDevCloudVariablesView = require '../lib/spark-dev-cloud-variables-view'
spark = require 'spark'
SettingsHelper = null

describe 'Cloud Variables View', ->
  activationPromise = null
  originalProfile = null
  sparkDev = null
  sparkDevCloudVariables = null
  sparkDevCloudVariablesView = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    activationPromise = atom.packages.activatePackage('spark-dev-cloud-variables').then ({mainModule}) ->
      sparkDevCloudVariables = mainModule

    sparkDevPromise = atom.packages.activatePackage('spark-dev').then ({mainModule}) ->
      sparkDev = mainModule
      SettingsHelper = sparkDev.SettingsHelper

    waitsForPromise ->
      activationPromise

    waitsForPromise ->
      sparkDevPromise

    runs ->
      originalProfile = SettingsHelper.getProfile()
      # For tests not to mess up our profile, we have to switch to test one...
      SettingsHelper.setProfile 'spark-dev-test'

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

      sparkDevCloudVariablesView = new SparkDevCloudVariablesView(null, sparkDev)
      sparkDevCloudVariablesView.setup()
      spyOn sparkDevCloudVariablesView, 'refreshVariable'
      SparkStub.stubSuccess spark, 'getVariable'

      body = sparkDevCloudVariablesView.find('#spark-dev-cloud-variables')

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
      expect(sparkDevCloudVariablesView.refreshVariable).toHaveBeenCalled()
      expect(sparkDevCloudVariablesView.refreshVariable).toHaveBeenCalledWith('foo')
      jasmine.unspy sparkDevCloudVariablesView, 'refreshVariable'

    it 'tests refreshing', ->
      SparkStub.stubSuccess spark, 'getVariable'
      sparkDevCloudVariablesView = new SparkDevCloudVariablesView(null, sparkDev)
      sparkDevCloudVariablesView.setup()
      body = sparkDevCloudVariablesView.find('#spark-dev-cloud-variables')

      waitsFor ->
        body.find('table > tbody > tr:eq(0) > td:eq(2)').text() == '1'

      runs ->
        expect(body.find('table > tbody > tr:eq(0) > td:eq(2)').hasClass('loading')).toBe(false)

    it 'checks event hooks', ->
      SparkStub.stubSuccess spark, 'getVariable'
      sparkDevCloudVariablesView = new SparkDevCloudVariablesView(null, sparkDev)
      sparkDevCloudVariablesView.setup()

      # Tests spark-dev:update-core-status
      spyOn sparkDevCloudVariablesView, 'listVariables'
      spyOn sparkDevCloudVariablesView, 'clearWatchers'
      atom.commands.dispatch workspaceElement, 'spark-dev:core-status-updated'
      expect(sparkDevCloudVariablesView.listVariables).toHaveBeenCalled()
      expect(sparkDevCloudVariablesView.clearWatchers).toHaveBeenCalled()
      jasmine.unspy sparkDevCloudVariablesView, 'listVariables'
      jasmine.unspy sparkDevCloudVariablesView, 'clearWatchers'

      # Tests spark-dev:logout
      SettingsHelper.clearCredentials()
      spyOn sparkDevCloudVariablesView, 'close'
      spyOn sparkDevCloudVariablesView, 'clearWatchers'
      atom.commands.dispatch workspaceElement, 'spark-dev:logout'
      expect(sparkDevCloudVariablesView.close).toHaveBeenCalled()
      expect(sparkDevCloudVariablesView.clearWatchers).toHaveBeenCalled()
      jasmine.unspy sparkDevCloudVariablesView, 'close'
      jasmine.unspy sparkDevCloudVariablesView, 'clearWatchers'

    it 'check watching variable', ->
      SparkStub.stubSuccess spark, 'getVariable'
      sparkDevCloudVariablesView = new SparkDevCloudVariablesView(null, sparkDev)
      sparkDevCloudVariablesView.setup()

      row = sparkDevCloudVariablesView.find('#spark-dev-cloud-variables table > tbody > tr:eq(0)')

      watchButton = row.find('td:eq(4) > button')
      refreshButton = row.find('td:eq(3) > button')

      expect(refreshButton.attr('disabled')).not.toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(false)
      expect(Object.keys(sparkDevCloudVariablesView.watchers).length).toEqual(0)

      jasmine.Clock.useMock()
      spyOn sparkDevCloudVariablesView, 'refreshVariable'

      watchButton.click()

      expect(refreshButton.attr('disabled')).toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(true)
      expect(Object.keys(sparkDevCloudVariablesView.watchers).length).toEqual(1)
      expect(Object.keys(sparkDevCloudVariablesView.watchers)).toEqual(['foo'])
      expect(sparkDevCloudVariablesView.refreshVariable).not.toHaveBeenCalled()
      watcher = sparkDevCloudVariablesView.watchers['foo']

      jasmine.Clock.tick(5001)

      expect(sparkDevCloudVariablesView.refreshVariable).toHaveBeenCalled()
      expect(sparkDevCloudVariablesView.refreshVariable).toHaveBeenCalledWith('foo')

      spyOn window, 'clearInterval'

      expect(window.clearInterval).not.toHaveBeenCalled()

      watchButton.click()

      expect(refreshButton.attr('disabled')).not.toEqual('disabled')
      expect(watchButton.hasClass('selected')).toBe(false)
      expect(Object.keys(sparkDevCloudVariablesView.watchers).length).toEqual(0)
      expect(window.clearInterval).toHaveBeenCalled()
      expect(window.clearInterval).toHaveBeenCalledWith(watcher)

      # TODO: Test clearing all watchers

      jasmine.unspy window, 'clearInterval'
      jasmine.unspy sparkDevCloudVariablesView, 'refreshVariable'

    it 'checks clearing watchers', ->
      sparkDevCloudVariablesView = new SparkDevCloudVariablesView(null, sparkDev)
      sparkDevCloudVariablesView.setup()

      sparkDevCloudVariablesView.watchers['foo'] = 'bar'
      spyOn window, 'clearInterval'
      expect(window.clearInterval).not.toHaveBeenCalled()

      expect(Object.keys(sparkDevCloudVariablesView.watchers).length).toEqual(1)
      sparkDevCloudVariablesView.clearWatchers()

      expect(window.clearInterval).toHaveBeenCalled()
      expect(window.clearInterval).toHaveBeenCalledWith('bar')
      expect(Object.keys(sparkDevCloudVariablesView.watchers).length).toEqual(0)

      jasmine.unspy window, 'clearInterval'
