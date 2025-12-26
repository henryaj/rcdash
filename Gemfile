# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.4.7"

gem "haml"
gem "oauth2"
gem "pg"
gem "rake"
gem "rest-client"
gem "sequel"
gem "sinatra"
gem "sinatra-contrib"

group :development, :test do
  gem "rubocop", "~> 1.68", require: false
  gem "rubocop-rspec", "~> 3.0", require: false
  gem "rubocop-sequel", "~> 0.3", require: false
end

group :development do
  gem "brakeman", require: false
  gem "guard"
  gem "guard-rspec"
end

group :test do
  gem "rack-test"
  gem "rspec"
  gem "simplecov", require: false
  gem "stub_env"
  gem "timecop", "~> 0.9"
  gem "webmock", "~> 3.20"
end
