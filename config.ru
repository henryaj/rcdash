require './app'

%w(ZULIP_SECRET_TOKEN DATABASE_URL).each do |e|
  ENV.fetch(e)
end

run BotServer