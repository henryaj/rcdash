#!/usr/bin/env ruby

require 'json'
require 'net/http'
require_relative './mac'

if !system("which tshark")
  puts "Unable to find tshark. Make sure 'tshark' is installed and on your PATH before running."
  exit 1
end

def send_macs(payload)
  uri = URI('https://rcdash.herokuapp.com/macs_seen')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  req.body = payload.to_json

  http.request(req)
end

def hash_macs(macs)
  macs.map do |i|
    Mac.hash(i)
  end
end

loop do
  `sudo tshark -Tfields -e eth.addr -a duration:10 > capture.tmp`
  `uniq capture.tmp > uniqcapture.tmp`

  uniq_capture = File.read("uniqcapture.tmp").split("\n")

  `rm capture.tmp uniqcapture.tmp`

  uniq_macs = uniq_capture.map { |line| line.split(",").last }
  hashed_macs = hash_macs(uniq_macs)

  send_macs({
    "seen" => hashed_macs
  })
end
