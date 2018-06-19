require 'sequel'
require 'sqlite3'
DB = Sequel.connect('sqlite://rcdash.db')

require './user'
require './botserver'
