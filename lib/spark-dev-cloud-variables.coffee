SparkDevCloudVariablesView = require './spark-dev-cloud-variables-view'

CompositeDisposable = null

module.exports =
  sparkDevCloudVariablesView: null

  activate: (state) ->
    {CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    atom.packages.activatePackage('spark-dev').then ({mainModule}) =>
      # Any Spark Dev dependent code should be placed here
      sparkDev = mainModule
      @sparkDevCloudVariablesView = new SparkDevCloudVariablesView(state.sparkDevCloudVariablesViewState, sparkDev)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @sparkDevCloudVariablesView.getUri()
          @sparkDevCloudVariablesView.setup()

      @disposables.add atom.commands.add 'atom-workspace',
        'spark-dev:append-menu': =>
          # Add itself to menu if user is authenticated
          if sparkDev.SettingsHelper.isLoggedIn()
            sparkDev.MenuManager.append [
              {
                label: 'Show cloud variables',
                command: 'spark-dev-cloud-variables-view:show-cloud-variables'
              }
            ]
        'spark-dev-cloud-variables-view:show-cloud-variables': =>
          sparkDev.openPane @sparkDevCloudVariablesView.getPath()

      atom.commands.dispatch @workspaceElement, 'spark-dev:update-menu'

  deactivate: ->
    @sparkDevCloudVariablesView?.destroy()
    @disposables.dispose()

  serialize: ->
    sparkDevCloudVariablesViewState: @sparkDevCloudVariablesView?.serialize()
