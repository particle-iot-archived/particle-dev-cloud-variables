CloudVariablesView = require './cloud-variables-view'

CompositeDisposable = null

module.exports =
  cloudVariablesView: null

  activate: (state) ->
    {CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @workspaceElement = atom.views.getView(atom.workspace)

    atom.packages.activatePackage('particle-dev').then ({mainModule}) =>
      # Any Particle Dev dependent code should be placed here
      particleDev = mainModule
      @cloudVariablesView = new CloudVariablesView(state.cloudVariablesViewState, particleDev)

      url = require 'url'
      atom.workspace.addOpener (uriToOpen) =>
        if uriToOpen == @cloudVariablesView.getUri()
          @cloudVariablesView.setup()

      @disposables.add atom.commands.add 'atom-workspace',
        'particle-dev:append-menu': =>
          # Add itself to menu if user is authenticated
          if particleDev.SettingsHelper.isLoggedIn()
            particleDev.MenuManager.append [
              {
                label: 'Show cloud variables',
                command: 'particle-dev-cloud-variables-view:show-cloud-variables'
              }
            ]
        'particle-dev-cloud-variables-view:show-cloud-variables': =>
          particleDev.openPane @cloudVariablesView.getPath()

      atom.commands.dispatch @workspaceElement, 'particle-dev:update-menu'

  deactivate: ->
    @cloudVariablesView?.destroy()
    @disposables.dispose()

  serialize: ->
    cloudVariablesViewState: @cloudVariablesView?.serialize()
