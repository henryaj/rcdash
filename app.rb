require 'sequel'
require 'sqlite3'
DB = Sequel.connect('sqlite://rcdash.db')

require './user'
require './botserver'
require './sniffer'

Thread.new { Sniffer.start_network_sniffing }
