(function() {
  if (window.GitLab == null) {
    window.GitLab = {};
  }

  GitLab.GfmAutoComplete = {
    dataLoading: false,
    dataLoaded: false,
    cachedData: {},
    dataSource: '',
    Emoji: {
      template: '<li>${name} <img alt="${name}" height="20" src="${path}" width="20" /></li>'
    },
    Members: {
      template: '<li>${username} <small>${title}</small></li>'
    },
    Labels: {
      template: '<li><span class="dropdown-label-box" style="background: ${color}"></span> ${title}</li>'
    },
    Issues: {
      template: '<li><small>${id}</small> ${title}</li>'
    },
    Milestones: {
      template: '<li>${title}</li>'
    },
    Loading: {
      template: '<li><i class="fa fa-refresh fa-spin"></i> Loading...</li>'
    },
    DefaultOptions: {
      sorter: function(query, items, searchKey) {
        if ((items[0].name != null) && items[0].name === 'loading') {
          return items;
        }
        return $.fn.atwho["default"].callbacks.sorter(query, items, searchKey);
      },
      filter: function(query, data, searchKey) {
        if (data[0] === 'loading') {
          return data;
        }
        return $.fn.atwho["default"].callbacks.filter(query, data, searchKey);
      },
      beforeInsert: function(value) {
        if (!GitLab.GfmAutoComplete.dataLoaded) {
          return this.at;
        } else {
          return value;
        }
      }
    },
    setup: function(input) {
      this.input = input || $('.js-gfm-input');
      this.destroyAtWho();
      this.setupAtWho();
      if (this.dataSource) {
        if (!this.dataLoading && !this.cachedData) {
          this.dataLoading = true;
          setTimeout((function(_this) {
            return function() {
              var fetch;
              fetch = _this.fetchData(_this.dataSource);
              return fetch.done(function(data) {
                _this.dataLoading = false;
                return _this.loadData(data);
              });
            };
          })(this), 1000);
        }
        if (this.cachedData != null) {
          return this.loadData(this.cachedData);
        }
      }
    },
    setupAtWho: function() {
      this.input.atwho({
        at: ':',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.path != null) {
              return _this.Emoji.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: ':${name}:',
        data: ['loading'],
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert
        }
      });
      this.input.atwho({
        at: '@',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.username != null) {
              return _this.Members.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}${username}',
        searchKey: 'search',
        data: ['loading'],
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(members) {
            return $.map(members, function(m) {
              var title;
              if (m.username == null) {
                return m;
              }
              title = m.name;
              if (m.count) {
                title += " (" + m.count + ")";
              }
              return {
                username: m.username,
                title: sanitize(title),
                search: sanitize(m.username + " " + m.name)
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '#',
        alias: 'issues',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(issues) {
            return $.map(issues, function(i) {
              if (i.title == null) {
                return i;
              }
              return {
                id: i.iid,
                title: sanitize(i.title),
                search: i.iid + " " + i.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '%',
        alias: 'milestones',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Milestones.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        insertTpl: '${atwho-at}"${title}"',
        data: ['loading'],
        callbacks: {
          beforeSave: function(milestones) {
            return $.map(milestones, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: "" + m.title
              };
            });
          }
        }
      });
      this.input.atwho({
        at: '!',
        alias: 'mergerequests',
        searchKey: 'search',
        displayTpl: (function(_this) {
          return function(value) {
            if (value.title != null) {
              return _this.Issues.template;
            } else {
              return _this.Loading.template;
            }
          };
        })(this),
        data: ['loading'],
        insertTpl: '${atwho-at}${id}',
        callbacks: {
          sorter: this.DefaultOptions.sorter,
          filter: this.DefaultOptions.filter,
          beforeInsert: this.DefaultOptions.beforeInsert,
          beforeSave: function(merges) {
            return $.map(merges, function(m) {
              if (m.title == null) {
                return m;
              }
              return {
                id: m.iid,
                title: sanitize(m.title),
                search: m.iid + " " + m.title
              };
            });
          }
        }
      });
      return this.input.atwho({
        at: '~',
        alias: 'labels',
        searchKey: 'search',
        displayTpl: this.Labels.template,
        insertTpl: '${atwho-at}${title}',
        callbacks: {
          beforeSave: function(merges) {
            var sanitizeLabelTitle;
            sanitizeLabelTitle = function(title) {
              if (/[\w\?&]+\s+[\w\?&]+/g.test(title)) {
                return "\"" + (sanitize(title)) + "\"";
              } else {
                return sanitize(title);
              }
            };
            return $.map(merges, function(m) {
              return {
                title: sanitizeLabelTitle(m.title),
                color: m.color,
                search: "" + m.title
              };
            });
          }
        }
      });
    },
    destroyAtWho: function() {
      return this.input.atwho('destroy');
    },
    fetchData: function(dataSource) {
      return $.getJSON(dataSource);
    },
    loadData: function(data) {
      this.cachedData = data;
      this.dataLoaded = true;
      this.input.atwho('load', '@', data.members);
      this.input.atwho('load', 'issues', data.issues);
      this.input.atwho('load', 'milestones', data.milestones);
      this.input.atwho('load', 'mergerequests', data.mergerequests);
      this.input.atwho('load', ':', data.emojis);
      this.input.atwho('load', '~', data.labels);
      return $(':focus').trigger('keyup');
    }
  };

}).call(this);
