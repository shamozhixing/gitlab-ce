class Gitlab::Seeder::Builds
  STAGES = %w[build test deploy notify]
  BUILDS = [
    { name: 'build:linux', stage: 'build', status: :success },
    { name: 'build:osx', stage: 'build', status: :success },
    { name: 'rspec:linux', stage: 'test', status: :success },
    { name: 'rspec:windows', stage: 'test', status: :success },
    { name: 'rspec:windows', stage: 'test', status: :success },
    { name: 'rspec:osx', stage: 'test', status_event: :success },
    { name: 'spinach:linux', stage: 'test', status: :pending },
    { name: 'spinach:osx', stage: 'test', status: :canceled },
    { name: 'cucumber:linux', stage: 'test', status: :running },
    { name: 'cucumber:osx', stage: 'test', status: :failed },
    { name: 'staging', stage: 'deploy', environment: 'staging', status: :success },
    { name: 'production', stage: 'deploy', environment: 'production', when: 'manual', status: :skipped },
    { name: 'slack', stage: 'notify', when: 'manual', status: :created },
  ]

  def initialize(project)
    @project = project
  end

  def seed!
    pipelines.each do |pipeline|
      begin
        BUILDS.each { |opts| build_create!(pipeline, opts) }
        commit_status_create!(pipeline, name: 'jenkins', stage: 'test', status: :success)
        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      ensure
        pipeline.build_updated
      end
    end
  end

  def pipelines
    master_pipelines + merge_request_pipelines
  end

  def master_pipelines
    create_pipelines_for(@project, 'master')
  rescue
    []
  end

  def merge_request_pipelines
    @project.merge_requests.last(5).map do |merge_request|
      create_pipelines(merge_request.source_project, merge_request.source_branch, merge_request.commits.last(5))
    end.flatten
  rescue
    []
  end

  def create_pipelines_for(project, ref)
    commits = project.repository.commits(ref, limit: 5)
    create_pipelines(project, ref, commits)
  end

  def create_pipelines(project, ref, commits)
    commits.map do |commit|
      project.pipelines.create(sha: commit.id, ref: ref)
    end
  end

  def build_create!(pipeline, opts = {})
    attributes = build_attributes_for(pipeline, opts)

    Ci::Build.create!(attributes) do |build|
      if opts[:name].start_with?('build')
        artifacts_cache_file(artifacts_archive_path) do |file|
          build.artifacts_file = file
        end

        artifacts_cache_file(artifacts_metadata_path) do |file|
          build.artifacts_metadata = file
        end
      end

      if %w(running success failed).include?(build.status)
        # We need to set build trace after saving a build (id required)
        build.trace = FFaker::Lorem.paragraphs(6).join("\n\n")
      end
    end
  end

  def commit_status_create!(pipeline, opts = {})
    attributes = commit_status_attributes_for(pipeline, opts)
    GenericCommitStatus.create!(attributes)
  end

  def commit_status_attributes_for(pipeline, opts)
    { name: 'test build', stage: 'test', stage_idx: stage_index(opts[:stage]),
      ref: 'master', tag: false, user: build_user, project: @project, pipeline: pipeline,
      created_at: Time.now, updated_at: Time.now
    }.merge(opts)
  end

  def build_attributes_for(pipeline, opts)
    commit_status_attributes_for(pipeline, opts).merge(commands: '$ build command')
  end

  def build_user
    @project.team.users.sample
  end

  def build_status
    Ci::Build::AVAILABLE_STATUSES.sample
  end

  def stage_index(stage)
    STAGES.index(stage) || 0
  end

  def artifacts_archive_path
    Rails.root + 'spec/fixtures/ci_build_artifacts.zip'
  end

  def artifacts_metadata_path
    Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz'
  end

  def artifacts_cache_file(file_path)
    cache_path = file_path.to_s.gsub('ci_', "p#{@project.id}_")

    FileUtils.copy(file_path, cache_path)
    File.open(cache_path) do |file|
      yield file
    end
  end
end

Gitlab::Seeder.quiet do
  Project.all.sample(10).each do |project|
    project_builds = Gitlab::Seeder::Builds.new(project)
    project_builds.seed!
  end
end
