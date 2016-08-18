class MigrateProjectFeatures < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON = 'Update project tools access method.'

  def up
    sql = %Q{
      INSERT INTO project_features(project_id, issues_access_level, merge_requests_access_level, wiki_access_level,
      builds_access_level, snippets_access_level, repository_access_level, created_at, updated_at)
        SELECT
        id AS project_id,
        CASE WHEN issues_enabled IS true THEN 20 ELSE 0 END AS issues_access_level,
        CASE WHEN merge_requests_enabled IS true THEN 20 ELSE 0 END AS merge_requests_access_level,
        CASE WHEN wiki_enabled IS true THEN 20 ELSE 0 END AS wiki_access_level,
        CASE WHEN builds_enabled IS true THEN 20 ELSE 0 END AS builds_access_level,
        CASE WHEN snippets_enabled IS true THEN 20 ELSE 0 END AS snippets_access_level,
        20 as repository_access_level,
        created_at,
        updated_at
        FROM projects
    }

    execute(sql)
  end
end
