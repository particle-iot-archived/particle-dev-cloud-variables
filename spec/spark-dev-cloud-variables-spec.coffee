{WorkspaceView} = require 'atom'
SparkDevCloudVariables = require '../lib/spark-dev-cloud-variables'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "SparkDevCloudVariables", ->
  activationPromise = null
  sparkDevPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView

  describe "when Spark Dev package is activated", ->
    it "sets up variables, openers and commands", ->
      spyOn atom.workspace, 'addOpener'
      spyOn atom.workspaceView, 'command'
      spyOn atom.workspaceView, 'trigger'

      sparkDevPromise = atom.packages.activatePackage('spark-dev')
      activationPromise = atom.packages.activatePackage('spark-dev-cloud-variables')

      waitsForPromise ->
        sparkDevPromise

      runs ->
        expect(atom.workspace.addOpener).toHaveBeenCalled()
        env = jasmine.getEnv()
        # Atom adds underscore-plus.isEqual to this array which breaks jasmine.any()
        env.equalityTesters_ = []
        expect(atom.workspaceView.command).toHaveBeenCalled()
        expect(atom.workspaceView.command).toHaveBeenCalledWith('spark-dev-cloud-variables-view:show-cloud-variables', jasmine.any(Function))
        expect(atom.workspaceView.command).toHaveBeenCalledWith('spark-dev:update-menu', jasmine.any(Function))

        expect(atom.workspaceView.trigger).toHaveBeenCalled()
        expect(atom.workspaceView.trigger).toHaveBeenCalledWith('spark-dev:update-menu')
