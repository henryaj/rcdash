#!/usr/bin/env bash

set -ex

if ! which wireshark; then
  sudo apt-get update
  sudo apt-get install -y wireshark 
fi

./init_db

source .envrc

bundle install
bundle exec rackup

