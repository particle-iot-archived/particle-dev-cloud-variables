'use babel';
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import {Disposable, CompositeDisposable} from 'atom';
import {View} from 'atom-space-pen-views';
import whenjs from 'when';
let $ = null;
let $$ = null;
let Subscriber = null;
let spark = null;

export default class CloudVariablesView extends View {
  static content() {
    this.div({id: 'particle-dev-cloud-variables-container'}, () => {
      this.div({id: 'particle-dev-cloud-variables', outlet: 'variablesList'});
    });
  }

  initialize(main) {
    this.main = main;
  }

  setup() {
    ({$, $$} = require('atom-space-pen-views'));

    spark = require('spark');
    spark.login({ accessToken: this.main.profileManager.accessToken });

    this.disposables = new CompositeDisposable;

    this.disposables.add(
      atom.commands.add('atom-workspace', {
        'particle-dev:update-core-status': () => {
          // Show some progress when core's status is downloaded
          this.variablesList.empty();
          return this.addClass('loading');
        },
        'particle-dev:core-status-updated': () => {
          // Refresh UI and watchers when current core changes
          this.listVariables();
          this.clearWatchers();
          return this.removeClass('loading');
        },
        'particle-dev:logout': () => {
          // Clear watchers and hide when user logs out
          this.clearWatchers();
          return this.close();
        }
      })
    );

    this.watchers = {};
    this.variablePromises = {};

    this.listVariables();

    return this;
  }

  serialize() {}

  destroy() {
    if (this.hasParent()) {
      this.remove();
    }
    return (this.disposables != null ? this.disposables.dispose() : undefined);
  }

  getTitle() {
    return 'Cloud variables';
  }

  getPath() {
    return 'cloud-variables';
  }

  getUri() {
    return `particle-dev://editor/${this.getPath()}`;
  }

  getDefaultLocation() {
    return 'bottom';
  }

  close() {
    const pane = atom.workspace.paneForUri(this.getUri());
    return (pane != null ? pane.destroy() : undefined);
  }

  // Propagate table with variables
  listVariables() {
    const variables = this.main.profileManager.getLocal('variables');
    this.variablesList.empty();

    if (!variables || (Object.keys(variables).length === 0)) {
      this.variablesList.append($$(function() {
        this.ul({class: 'background-message'}, () => {
          this.li('No variables registered');
        });
      })
      );
    } else {
      const table = $$(function() {
        this.table(() => {
          this.thead(() => {
            this.tr(() => {
              this.th('Name');
              this.th('Type');
              this.th('Value');
              this.th('Refresh');
              this.th('Watch');
            });
          });
          this.tbody(() => {
            this.raw('');
          });
        });
      });

      for (var variable of Object.keys(variables)) {
        const row = $$(function() {
          this.table(() => {
            this.tr({'data-id': variable}, () => {
              this.td(variable);
              this.td(variables[variable]);
              this.td({class: 'loading'});
              this.td(() => {
                this.button({class: 'btn btn-sm icon icon-sync'});
              });
              this.td(() => {
                this.button({class: 'btn btn-sm icon icon-eye'});
              });
            });
          });
        });

        row.find('td:eq(3) button').on('click', event => {
          this.refreshVariable($(event.currentTarget).parent().parent().attr('data-id'));
        });

        row.find('td:eq(4) button').on('click', event => {
          this.toggleWatchVariable($(event.currentTarget).parent().parent().attr('data-id'));
        });

        table.find('tbody').append(row.find('tbody >'));
      }

      this.variablesList.append(table);

      // Get initial values
      return (() => {
        const result = [];
        for (variable of Array.from(Object.keys(variables))) {
          result.push(this.refreshVariable(variable));
        }
        return result;
      })();
    }
  }

  // Get variable value from the cloud
  refreshVariable(variableName) {
    const dfd = whenjs.defer();

    const cell = this.find(`#particle-dev-cloud-variables [data-id=${variableName}] td:eq(2)`);
    cell.addClass('loading');
    cell.text('');
    let promise = this.variablePromises[variableName];
    if (!!promise) {
      promise._handler.resolve();
    }
    promise = spark.getVariable(this.main.profileManager.currentDevice.id, variableName);
    this.variablePromises[variableName] = promise;
    promise.done(e => {
      if (!e) {
        dfd.resolve(null);
        return;
      }

      delete this.variablePromises[variableName];
      cell.removeClass();

      if (!!e.ok) {
        cell.addClass('icon icon-issue-opened text-error');
        return dfd.reject();
      } else {
        cell.text(e.result);
        return dfd.resolve(e.result);
      }
    }
    , e => {
      delete this.variablePromises[variableName];
      cell.removeClass();
      cell.addClass('icon icon-issue-opened text-error');
      return dfd.reject();
    });
    return dfd.promise;
  }

  // Toggle watching variable
  toggleWatchVariable(variableName) {
    const row = this.find(`#particle-dev-cloud-variables [data-id=${variableName}]`);
    const watchButton = row.find('td:eq(4) button');
    const refreshButton = row.find('td:eq(3) button');
    const valueCell = row.find('td:eq(2)');

    if (watchButton.hasClass('selected')) {
      watchButton.removeClass('selected');
      refreshButton.removeAttr('disabled');
      clearInterval(this.watchers[variableName]);
      return delete this.watchers[variableName];
    } else {
      watchButton.addClass('selected');
      refreshButton.attr('disabled', 'disabled');
      // Gget variable every 5 seconds (empirical value)
      return this.watchers[variableName] = setInterval(() => {
        return this.refreshVariable(variableName);
      }
      , 5000);
    }
  }

  // Remove all variable watchers
  clearWatchers() {
    for (let key of Array.from(Object.keys(this.watchers))) {
      clearInterval(this.watchers[key]);
    }
    return this.watchers = {};
  }
};
