Rake::Task["spec"].clear if Rake::Task.task_defined?('spec')

namespace :spec do
  desc 'GitLab | RSpec | Run request specs'
  task :api do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @api)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | RSpec | Run feature specs'
  task :feature, [:split] do |task, args|
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec --).concat(split_feature_specs(args[:split]))
    ]

    run_commands(cmds)
  end

  desc 'GitLab | RSpec | Run model specs'
  task :models do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @models)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | RSpec | Run service specs'
  task :services do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @services)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | RSpec | Run lib specs'
  task :lib do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag @lib)
    ]
    run_commands(cmds)
  end

  desc 'GitLab | RSpec | Run other specs'
  task :other do
    cmds = [
      %W(rake gitlab:setup),
      %W(rspec spec --tag ~@api --tag ~@feature --tag ~@models --tag ~@lib --tag ~@services)
    ]
    run_commands(cmds)
  end
end

desc "GitLab | Run specs"
task :spec do
  cmds = [
    %W(rake gitlab:setup),
    %W(rspec spec),
  ]
  run_commands(cmds)
end

def run_commands(cmds)
  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd) or raise("#{cmd} failed!")
  end
end

def split_feature_specs(option = nil)
  files = Dir["spec/features/**/*_spec.rb"]
  count = files.length

  if option == 'first_half'
    files[0...count/2]
  elsif option == 'last_half'
    files[count/2..-1]
  else
    []
  end
end
