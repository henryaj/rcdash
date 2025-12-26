# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run RuboCop linter"
task :lint do
  sh "bundle exec rubocop"
end

desc "Run RuboCop with auto-correct"
task :lint_fix do
  sh "bundle exec rubocop -A"
end

desc "Run tests with coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task[:spec].invoke
end

desc "Run security scan with Brakeman"
task :security do
  sh "bundle exec brakeman -q --no-pager --force"
end

desc "Run all checks (lint, security, tests)"
task check: %i[lint security spec]

task default: :spec
