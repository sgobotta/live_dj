.PHONY: server setup test

export MIX_ENV ?= dev
export SECRET_KEY_BASE ?= $(shell mix phx.gen.secret)

# Enables bash commands in the whole document
# SHELL := /bin/bash

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`

default: help

#db: @ Bundles the services and the setup commands
db: docker.services setup

#docker.services: @ Starts a detached postgresql service with an adminer instance at port 8080
docker.services: SHELL:=/bin/bash
docker.services: 
	source .env && docker-compose up -d

#ecto.create: @ Creates the storage for the repo
ecto.create: SHELL:=/bin/bash
ecto.create: 
	source .env && mix ecto.create

#ecto.reset: @ Drops your current database, recreates and migrates it again
ecto.reset: SHELL:=/bin/bash
ecto.reset:
	source .env && mix ecto.reset

#ecto.setup: @ Creates and migrates the database
ecto.setup: SHELL:=/bin/bash
ecto.setup:
	source .env && mix ecto.setup

#help: @ Shows help topics
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

#install: @ Installs all dependencies
install: install.deps install.npm

#install.deps: @ Installs dependencies from mix.exs
install.deps:
	@mix deps.get

#install.npm: @ Installs dependencies from assets/package.json
install.npm:
	cd assets; npm i

#mix.test: @ Runs tests
mix.test: SHELL:=/bin/bash
mix.test:
	source .env && mix test

#reset: @ Runs the ecto.reset command
reset: ecto.reset

#server: @ Starts an interactive elixir shell
server: SHELL:=/bin/bash
server: docker.services
server:
	source .env && iex --name $(APP_NAME)@127.0.0.1 -S mix phx.server

#setup: @ Bundles the ecto.create and ecto.setup commands
setup: ecto.create ecto.setup

#test: @ Run mix tests
test: MIX_ENV=test
test: SHELL:=/bin/bash
test:
	source .env && mix test
