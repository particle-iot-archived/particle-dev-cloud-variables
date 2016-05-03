CloudVariables = require '../lib/cloud-variables'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "CloudVariables", ->
  activationPromise = null
  particleDevPromise = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

  describe "when Particle Dev package is activated", ->
    it "sets up variables, openers and commands", ->
      spyOn atom.workspace, 'addOpener'

      particleDevPromise = atom.packages.activatePackage('particle-dev')
      activationPromise = atom.packages.activatePackage('particle-dev-cloud-variables')

      waitsForPromise ->
        particleDevPromise

      runs ->
        expect(atom.workspace.addOpener).toHaveBeenCalled()
