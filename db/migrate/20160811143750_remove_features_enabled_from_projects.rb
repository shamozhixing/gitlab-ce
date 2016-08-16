# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveFeaturesEnabledFromProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    remove_column :projects, :issues_enabled
    remove_column :projects, :merge_requests_enabled
    remove_column :projects, :builds_enabled
    remove_column :projects, :wiki_enabled
    remove_column :projects, :snippets_enabled
  end

  # Ugly SQL but the only way i found to make it work on both Postgres and Mysql
  # It will be slow but it is ok since it is a revert method
  def down
    add_column_with_default(:projects, :issues_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :merge_requests_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :builds_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :wiki_enabled, :boolean, default: true, allow_null: false)
    add_column_with_default(:projects, :snippets_enabled, :boolean, default: true, allow_null: false)

    sql = %Q{
      UPDATE projects
      SET
      issues_enabled = COALESCE((SELECT CASE WHEN issues_access_level = 20 THEN true ELSE false END AS issues_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      merge_requests_enabled = COALESCE((SELECT CASE WHEN merge_requests_access_level = 20 THEN true ELSE false END AS merge_requests_enabled FROM project_features WHERE project_features.project_id = projects.id),true),
      wiki_enabled = COALESCE((SELECT CASE WHEN wiki_access_level = 20 THEN true ELSE false END AS wiki_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      builds_enabled = COALESCE((SELECT CASE WHEN builds_access_level = 20 THEN true ELSE false END AS builds_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      snippets_enabled = COALESCE((SELECT CASE WHEN snippets_access_level = 20 THEN true ELSE false END AS snippets_enabled FROM project_features WHERE project_features.project_id = projects.id),true)
    }

    execute(sql)
  end
end
