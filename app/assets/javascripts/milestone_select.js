(function() {
  this.MilestoneSelect = (function() {
    function MilestoneSelect(currentProject) {
      var _this;
      if (currentProject != null) {
        _this = this;
        this.currentProject = JSON.parse(currentProject);
      }
      $('.js-milestone-select').each(function(i, dropdown) {
        var $block, $dropdown, $loading, $selectbox, $sidebarCollapsedValue, $value, abilityName, collapsedSidebarLabelTemplate, defaultLabel, issuableId, issueUpdateURL, milestoneLinkNoneTemplate, milestoneLinkTemplate, milestonesUrl, projectId, selectedMilestone, showAny, showNo, showUpcoming, useId;
        $dropdown = $(dropdown);
        projectId = $dropdown.data('project-id');
        milestonesUrl = $dropdown.data('milestones');
        issueUpdateURL = $dropdown.data('issueUpdate');
        selectedMilestone = $dropdown.data('selected');
        showNo = $dropdown.data('show-no');
        showAny = $dropdown.data('show-any');
        showUpcoming = $dropdown.data('show-upcoming');
        useId = $dropdown.data('use-id');
        defaultLabel = $dropdown.data('default-label');
        issuableId = $dropdown.data('issuable-id');
        abilityName = $dropdown.data('ability-name');
        $selectbox = $dropdown.closest('.selectbox');
        $block = $selectbox.closest('.block');
        $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon');
        $value = $block.find('.value');
        $loading = $block.find('.block-loading').fadeOut();
        if (issueUpdateURL) {
          milestoneLinkTemplate = _.template('<a href="/<%- namespace %>/<%- path %>/milestones/<%- iid %>" class="bold has-tooltip" data-container="body" title="<%- remaining %>"><%- title %></a>');
          milestoneLinkNoneTemplate = '<span class="no-value">None</span>';
          collapsedSidebarLabelTemplate = _.template('<span class="has-tooltip" data-container="body" title="<%- remaining %>" data-placement="left"> <%- title %> </span>');
        }
        return $dropdown.glDropdown({
          data: function(term, callback) {
            return $.ajax({
              url: milestonesUrl
            }).done(function(data) {
              var extraOptions;
              extraOptions = [];
              if (showAny) {
                extraOptions.push({
                  id: 0,
                  name: '',
                  title: 'Any Milestone'
                });
              }
              if (showNo) {
                extraOptions.push({
                  id: -1,
                  name: 'No Milestone',
                  title: 'No Milestone'
                });
              }
              if (showUpcoming) {
                extraOptions.push({
                  id: -2,
                  name: '#upcoming',
                  title: 'Upcoming'
                });
              }
              if (extraOptions.length > 2) {
                extraOptions.push('divider');
              }
              return callback(extraOptions.concat(data));
            });
          },
          filterable: true,
          search: {
            fields: ['title']
          },
          selectable: true,
          toggleLabel: function(selected) {
            if (selected && 'id' in selected) {
              return selected.title;
            } else {
              return defaultLabel;
            }
          },
          fieldName: $dropdown.data('field-name'),
          text: function(milestone) {
            return _.escape(milestone.title);
          },
          id: function(milestone) {
            if (!useId) {
              return milestone.name;
            } else {
              return milestone.id;
            }
          },
          isSelected: function(milestone) {
            return milestone.name === selectedMilestone;
          },
          hidden: function() {
            $selectbox.hide();
            return $value.css('display', '');
          },
          clicked: function(selected) {
            var data, isIssueIndex, isMRIndex, page;
            page = $('body').data('page');
            isIssueIndex = page === 'projects:issues:index';
            isMRIndex = (page === page && page === 'projects:merge_requests:index');
            if ($dropdown.hasClass('js-filter-bulk-update')) {
              return;
            }
            if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
              if (selected.name != null) {
                selectedMilestone = selected.name;
              } else {
                selectedMilestone = '';
              }
              return Issuable.filterResults($dropdown.closest('form'));
            } else if ($dropdown.hasClass('js-filter-submit')) {
              return $dropdown.closest('form').submit();
            } else {
              selected = $selectbox.find('input[type="hidden"]').val();
              data = {};
              data[abilityName] = {};
              data[abilityName].milestone_id = selected != null ? selected : null;
              $loading.fadeIn();
              $dropdown.trigger('loading.gl.dropdown');
              return $.ajax({
                type: 'PUT',
                url: issueUpdateURL,
                data: data
              }).done(function(data) {
                $dropdown.trigger('loaded.gl.dropdown');
                $loading.fadeOut();
                $selectbox.hide();
                $value.css('display', '');
                if (data.milestone != null) {
                  data.milestone.namespace = _this.currentProject.namespace;
                  data.milestone.path = _this.currentProject.path;
                  data.milestone.remaining = $.timefor(data.milestone.due_date);
                  $value.html(milestoneLinkTemplate(data.milestone));
                  return $sidebarCollapsedValue.find('span').html(collapsedSidebarLabelTemplate(data.milestone));
                } else {
                  $value.html(milestoneLinkNoneTemplate);
                  return $sidebarCollapsedValue.find('span').text('No');
                }
              });
            }
          }
        });
      });
    }

    return MilestoneSelect;

  })();

}).call(this);
