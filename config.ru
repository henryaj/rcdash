# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", File.dirname(__FILE__)))

missing = []
%w[SALT ZULIP_SECRET_TOKEN DATABASE_URL RC_OAUTH_CLIENT_ID RC_OAUTH_CLIENT_SECRET BASE_URL SESSION_SECRET].each do |e|
  missing << e unless ENV[e]
end

if missing.any?
  puts "Missing env vars: #{missing.join(', ')}"
  exit 1
end

require "auth"
require "server"
run Server.new
