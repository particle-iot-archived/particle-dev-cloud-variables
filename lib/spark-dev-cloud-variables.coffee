SparkDevCloudVariablesView = require './spark-dev-cloud-variables-view'
sparkDev = null

module.exports =
  sparkDevCloudVariablesView: null

  activate: (state) ->
    atom.packages.activatePackage('spark-dev').then ({mainModule}) =>
      # Any Spark Dev dependent code should be placed here
      sparkDev = mainModule
      @sparkDevCloudVariablesView = new SparkDevCloudVariablesView(state.sparkDevCloudVariablesViewState, sparkDev)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @sparkDevCloudVariablesView.getUri()
          @sparkDevCloudVariablesView.setup()

      atom.workspaceView.command 'spark-dev-cloud-variables-view:show-cloud-variables', =>
        atom.workspace.open @sparkDevCloudVariablesView.getUri()

      atom.workspaceView.command 'spark-dev:update-menu', =>
        # Add itself to menu if user is authenticated
        if sparkDev.SettingsHelper.isLoggedIn()
          sparkDev.MenuManager.append [
            {
              label: 'Show cloud variables',
              command: 'spark-dev-cloud-variables-view:show-cloud-variables'
            }
          ]
      atom.workspaceView.trigger 'spark-dev:update-menu'


  deactivate: ->
    @sparkDevCloudVariablesView?.destroy()

  serialize: ->
    sparkDevCloudVariablesViewState: @sparkDevCloudVariablesView?.serialize()
