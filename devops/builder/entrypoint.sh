#!/usr/bin/env bash

bin="bin/livedj"
module="Livedj"

hello() {
  set -e

  # Simple application interaction
 $bin eval "IO.puts(${module}.hello())"
}

create_db() {
  set -e

  echo ======== Create DB ========
  $bin eval "${module}.Release.create_db()"
}

migrate() {
  set -e

  echo ======== Starting ecto migration ========
  $bin eval "${module}.Release.migrate()"
}

seeds() {
  set -e

  echo ======== Creating seeds ========
  $bin eval "${module}.Release.seed()"
}

setup_db() {
  set -e

  echo Setting up DB...
  # Run the create db
  create_db
  # Run the migrate script
  migrate
  # Run seeds creation
  seeds
}

start() {
  set -e

  # Run the setup_db script
  setup_db

  echo ======== Starting livedj ========
  $bin start
}

case $1 in
  hello) "$@"; exit;;
  create_db) "$@"; exit;;
  migrate) "$@"; exit;;
  seeds) "$@"; exit;;
  setup_db) "$@"; exit;;
  start) "$@"; exit;;
esac
