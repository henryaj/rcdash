# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/vendor/"

    add_group "Models", "lib/user.rb"
    add_group "Handlers", %w[lib/auth.rb lib/zulip.rb]
    add_group "Web", "lib/server.rb"
    add_group "Utilities", "lib/mac.rb"

    minimum_coverage 70
    minimum_coverage_by_file 40
  end
end

require "stub_env"
require "webmock/rspec"
require "timecop"

# Disable external HTTP requests in tests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.include StubEnv::Helpers

  # Reset time after each test
  config.after do
    Timecop.return
  end

  config.order = :random
  Kernel.srand config.seed
end
