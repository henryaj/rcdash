require './app'

%w(ZULIP_SECRET_TOKEN).each do |e|
  ENV.fetch(e)
end

run BotServer