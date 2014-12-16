SparkDevCloudVariablesView = require './spark-dev-cloud-variables-view'

module.exports =
  sparkDev: null
  sparkDevCloudVariablesView: null

  activate: (state) ->
    atom.packages.activatePackage('spark-dev').then ({mainModule}) =>
      sparkDev = mainModule
      @sparkDevCloudVariablesView = new SparkDevCloudVariablesView(state.sparkDevCloudVariablesViewState, sparkDev)

    url = require 'url'
    atom.workspace.addOpener (uriToOpen) =>
      if uriToOpen == @sparkDevCloudVariablesView.getUri()
        @sparkDevCloudVariablesView.setup()


  deactivate: ->
    @sparkDevCloudVariablesView.destroy()

  serialize: ->
    sparkDevCloudVariablesViewState: @sparkDevCloudVariablesView.serialize()
