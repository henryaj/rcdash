require 'sequel'
require 'pg'
DB = Sequel.connect(ENV.fetch("DATABASE_URL"))

unless DB.table_exists?(:users)
  DB.create_table :users do
    primary_key :id
    String :mac
    String :email
    String :zulip_id
    String :name
    DateTime :last_seen
  end
end

require './user'
require './server'
