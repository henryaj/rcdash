require './app'

%w(ZULIP_SECRET_TOKEN DATABASE_URL RC_OAUTH_CLIENT_ID RC_OAUTH_CLIENT_SECRET BASE_URL SESSION_SECRET).each do |e|
  ENV.fetch(e)
end

run Server