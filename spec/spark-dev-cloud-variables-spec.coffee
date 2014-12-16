{WorkspaceView} = require 'atom'
SparkDevCloudVariables = require '../lib/spark-dev-cloud-variables'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "SparkDevCloudVariables", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('spark-dev-cloud-variables')

  describe "when the spark-dev-cloud-variables:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.spark-dev-cloud-variables')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'spark-dev-cloud-variables:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.spark-dev-cloud-variables')).toExist()
        atom.commands.dispatch atom.workspaceView.element, 'spark-dev-cloud-variables:toggle'
        expect(atom.workspaceView.find('.spark-dev-cloud-variables')).not.toExist()
