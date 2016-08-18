class RemoveFeaturesEnabledFromProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :projects, :issues_enabled
    remove_column :projects, :merge_requests_enabled
    remove_column :projects, :builds_enabled
    remove_column :projects, :wiki_enabled
    remove_column :projects, :snippets_enabled
  end

  # Ugly SQL but necessary to work on both Postgres and Mysql
  def down
    add_column :projects, :issues_enabled, :boolean, default: true, null: false
    add_column :projects, :merge_requests_enabled, :boolean, default: true, null: false
    add_column :projects, :builds_enabled, :boolean, default: true, null: false
    add_column :projects, :wiki_enabled, :boolean, default: true, null: false
    add_column :projects, :snippets_enabled, :boolean, default: true, null: false

    sql = %Q{
      UPDATE projects
      SET
      issues_enabled = COALESCE((SELECT CASE WHEN issues_access_level = 20 THEN true ELSE false END AS issues_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      merge_requests_enabled = COALESCE((SELECT CASE WHEN merge_requests_access_level = 20 THEN true ELSE false END AS merge_requests_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      wiki_enabled = COALESCE((SELECT CASE WHEN wiki_access_level = 20 THEN true ELSE false END AS wiki_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      builds_enabled = COALESCE((SELECT CASE WHEN builds_access_level = 20 THEN true ELSE false END AS builds_enabled FROM project_features WHERE project_features.project_id = projects.id), true),
      snippets_enabled = COALESCE((SELECT CASE WHEN snippets_access_level = 20 THEN true ELSE false END AS snippets_enabled FROM project_features WHERE project_features.project_id = projects.id), true)
    }

    execute(sql)
  end
end
