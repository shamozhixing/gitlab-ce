(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.ProtectedBranchSelect = (function() {
    function ProtectedBranchSelect(currentProject) {
      this.toggleCreateNewButton = bind(this.toggleCreateNewButton, this);
      this.getProtectedBranches = bind(this.getProtectedBranches, this);
      $('.dropdown-footer').hide();
      this.dropdown = $('.js-protected-branch-select').glDropdown({
        data: this.getProtectedBranches,
        filterable: true,
        remote: false,
        search: {
          fields: ['title']
        },
        selectable: true,
        toggleLabel: function(selected) {
          if (selected && 'id' in selected) {
            return selected.title;
          } else {
            return 'Protected Branch';
          }
        },
        fieldName: 'protected_branch[name]',
        text: function(protected_branch) {
          return _.escape(protected_branch.title);
        },
        id: function(protected_branch) {
          return _.escape(protected_branch.id);
        },
        onFilter: this.toggleCreateNewButton,
        clicked: function() {
          return $('.protect-branch-btn').attr('disabled', false);
        }
      });
      $('.create-new-protected-branch').on('click', (function(_this) {
        return function(event) {
          _this.dropdown.data('glDropdown').remote.execute();
          return _this.dropdown.data('glDropdown').selectRowAtIndex(event, 0);
        };
      })(this));
    }

    ProtectedBranchSelect.prototype.getProtectedBranches = function(term, callback) {
      if (this.selectedBranch) {
        return callback(gon.open_branches.concat(this.selectedBranch));
      } else {
        return callback(gon.open_branches);
      }
    };

    ProtectedBranchSelect.prototype.toggleCreateNewButton = function(branchName) {
      this.selectedBranch = {
        title: branchName,
        id: branchName,
        text: branchName
      };
      if (branchName === '') {
        $('.protected-branch-select-footer-list').addClass('hidden');
        return $('.dropdown-footer').hide();
      } else {
        $('.create-new-protected-branch').text("Create Protected Branch: " + branchName);
        $('.protected-branch-select-footer-list').removeClass('hidden');
        return $('.dropdown-footer').show();
      }
    };

    return ProtectedBranchSelect;

  })();

}).call(this);
