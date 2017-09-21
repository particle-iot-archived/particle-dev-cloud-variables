'use babel';

let CloudVariablesView = null;
let CompositeDisposable = null;

export default {
	cloudVariablesView: null,

	activate(state) {
		({CompositeDisposable} = require('atom'));
		this.disposables = new CompositeDisposable;
		this.workspaceElement = atom.views.getView(atom.workspace);

		return atom.packages.activatePackage('particle-dev').then(({mainModule}) => {
			this.main = mainModule;
			// Any Particle Dev dependent code should be placed here
			CloudVariablesView = require('./cloud-variables-view');
			this.cloudVariablesView = new CloudVariablesView(this.main);

			this.disposables.add(
				atom.commands.add('atom-workspace', {
					'particle-dev:append-menu': () => {
						// Add itself to menu if user is authenticated
						if (this.main.profileManager.isLoggedIn) {
							this.main.MenuManager.append([
								{
									label: 'Show cloud variables',
									command: 'particle-dev-cloud-variables-view:show-cloud-variables'
								}
							]);
						}
					},
					'particle-dev-cloud-variables-view:show-cloud-variables': () => {
						this.show();
					}
				})
			);

			return atom.commands.dispatch(this.workspaceElement, 'particle-dev:update-menu');
		});
	},

	deactivate() {
		if (this.cloudVariablesView != null) {
			this.cloudVariablesView.destroy();
		}
		return this.disposables.dispose();
	},

	show() {
		atom.workspace.open(this.cloudVariablesView.setup());
	}
};
