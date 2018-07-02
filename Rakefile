task :migrate_db do
  require 'sequel'
  DB = Sequel.connect(ENV.fetch("DATABASE_URL"))
  require_relative 'lib/mac'
  require_relative 'lib/user'
  
  User.all do |u|
    mac = u.mac
    if mac.length == 17
      hashed = Mac.hash(u.mac)
      u.mac = hashed
      u.save
    end

    puts u.inspect
  end
end
