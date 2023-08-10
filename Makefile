.PHONY: setup test

export MIX_ENV ?= dev

LOCAL_ENV_FILE = .env
PROD_ENV_FILE = .env.prod
APP_NAME = `grep 'APP_NAME=' .env | sed -e 's/\[//g' -e 's/ //g' -e 's/APP_NAME=//'`
DOCKERFILE_DIR = devops/builder/
CONTAINER_NAME = livedj_app
IMAGE_NAME = livedj_app

# Add env variables if needed
ifneq (,$(wildcard ${LOCAL_ENV_FILE}))
	include ${LOCAL_ENV_FILE}
    export
endif

export GREEN=\033[0;32m
export NOFORMAT=\033[0m

default: help

#🔍 check: @ Runs all code verifications
check: check.lint check.dialyzer test

#🔍 check.dialyzer: @ Runs a static code analysis
check.dialyzer: SHELL:=/bin/bash
check.dialyzer:
	@source ${LOCAL_ENV_FILE} && mix check.dialyzer

#🔍 check.lint: @ Strictly runs a code formatter
check.lint: SHELL:=/bin/bash
check.lint:
	@source ${LOCAL_ENV_FILE} && mix check.format
	@source ${LOCAL_ENV_FILE} && mix check.credo

#🧹 clean.uploads: @ Removes all files from the uploads dir
clean.uploads: SHELL:=/bin/bash
clean.uploads:
	@source ${LOCAL_ENV_FILE} && \
		find ${UPLOADS_PATH} -path ${UPLOADS_PATH}/.gitkeep -prune -o -name "*.*" -exec /bin/rm -f {} \;

#🐳 docker.build: @ Builds a new image for the service.
docker.build:
	@docker build \
		./ \
		--build-arg UPLOADS_PATH=${UPLOADS_PATH} \
		-f $(DOCKERFILE_DIR)/Dockerfile \
		-t $(CONTAINER_NAME)

#🐳 docker.connect: @ Connect to the running container
docker.connect:
	@docker exec -it $(CONTAINER_NAME) /bin/sh

#🐳 docker.delete: @ Delete the docker container
docker.delete: CONTAINER_NAME:=$(CONTAINER_NAME)
docker.delete:
	@docker rm $(CONTAINER_NAME) 2> /dev/null || true

#🐳 docker.logs: @ Show logs for the docker container
docker.logs: CONTAINER_NAME:=$(CONTAINER_NAME)
docker.logs:
	@docker logs $(CONTAINER_NAME) -f

#🐳 docker.release: @ Re-create a docker image and run it
docker.release: PORT:=5000
docker.release: INTERNAL_PORT:=5001
docker.release: docker.stop docker.delete docker.build docker.run

#🐳 docker.rerun: @ Stops and deletes old container to re-run a fresh new container
docker.rerun: PORT:=5000
docker.rerun: INTERNAL_PORT:=5001
docker.rerun: docker.stop docker.delete docker.run

#🐳 docker.run: @ Run the docker container
docker.run: PORT:=5000
docker.run: INTERNAL_PORT:=5001
docker.run: CONTAINER_NAME:=$(CONTAINER_NAME)
docker.run: IMAGE_NAME:=$(IMAGE_NAME)
docker.run:
	@docker run --detach --name $(CONTAINER_NAME) --network devops_livedj_storage -p $(PORT):$(INTERNAL_PORT) --env PORT=$(INTERNAL_PORT) --env-file .env.prod $(IMAGE_NAME)

#🐳 docker.stop: @ Stop the docker container
docker.stop: CONTAINER_NAME:=$(CONTAINER_NAME)
docker.stop:
	@docker container stop $(CONTAINER_NAME) 2> /dev/null || true

#📖 docs: @ Generates HTML documentation
docs:
	@mix docs

#❓ help: @ Displays this message
help:
	@echo ""
	@echo "List of available MAKE targets for development usage."
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Examples:"
	@echo ""
	@echo "	make ${GREEN}start${NOFORMAT}	- Starts docker services"
	@echo "	make ${GREEN}setup${NOFORMAT}	- Set up the whole project and database"
	@echo "	make ${GREEN}server${NOFORMAT}	- Starts a development server"
	@echo "	make ${GREEN}stop${NOFORMAT}	- Stops docker services"
	@echo ""
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(firstword $(MAKEFILE_LIST))| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "${GREEN}%-30s${NOFORMAT} %s\n", $$1, $$2}'

#💻 lint: @ Formats code
lint: SHELL:=/bin/bash
lint: MIX_ENV=dev
lint:
	@mix format
	@mix check.credo

#💣 reset: @ Cleans dependencies then re-installs and compiles them for all envs
reset: SHELL:=/bin/bash
reset: reset.dev reset.test

#💣 reset.dev: @ Cleans dependencies then re-installs and compiles them1 for dev env
reset.dev: SHELL:=/bin/bash
reset.dev: MIX_ENV=dev
reset.dev:
	@echo "🧹 Cleaning db and dependencies for dev..."
	@mix reset

#💣 reset.test: @ Cleans dependencies then re-installs and compiles them1 for test env
reset.test: SHELL:=/bin/bash
reset.test: MIX_ENV=test
reset.test:
	@echo "🧹 Cleaning db and dependencies for test..."
	@mix reset

#💣 reset.ecto: @ Resets database for all envs
reset.ecto: SHELL:=/bin/bash
reset.ecto: reset.ecto.dev reset.ecto.test

#💣 reset.ecto.dev: @ Resets database for dev env
reset.ecto.dev: SHELL:=/bin/bash
reset.ecto.dev: MIX_ENV=dev
reset.ecto.dev:
	@echo "🧹 Cleaning db for dev env..."
	@mix reset.ecto

#💣 reset.ecto.test: @ Resets database for test env
reset.ecto.test: SHELL:=/bin/bash
reset.ecto.test: MIX_ENV=test
reset.ecto.test:
	@echo "🧹 Cleaning db for test env..."
	@mix reset.ecto

#📦 setup: @ Installs dependencies and set up database for dev and test envs
setup: SHELL:=/bin/bash
setup: setup.dev setup.test

#📦 setup.dev: @ Installs dependencies and set up database for dev env
setup.dev: SHELL:=/bin/bash
setup.dev: MIX_ENV=dev
setup.dev:
	@mix setup
	@mix git_hooks.install

#📦 setup.test: @ Installs dependencies and set up database for test env
setup.test: SHELL:=/bin/bash
setup.test: MIX_ENV=test
setup.test:
	@mix setup

#📦 setup.deps: @ Installs dependencies for development
setup.deps: setup.deps.dev setup.deps.test

#📦 setup.deps.ci: @ Installs dependencies for the CI environment
setup.deps.ci:
	@mix install

#📦 setup.deps.dev: @ Installs dependencies only for dev env
setup.deps.dev: SHELL:=/bin/bash
setup.deps.dev: MIX_ENV=dev
setup.deps.dev:
	@mix install

#📦 setup.deps.test: @ Installs dependencies only for test env
setup.deps.test: SHELL:=/bin/bash
setup.deps.test: MIX_ENV=test
setup.deps.test:
	@mix install

#💻 server: @ Starts a server with an interactive elixir shell.
server: SHELL:=/bin/bash
server:
	@iex --name ${APP_NAME}@127.0.0.1 -S mix phx.server

#🧪 test: @ Runs all test suites
test: SHELL:=/bin/bash
test: MIX_ENV=test
test:
	@mix test

#🧪 test.cover: @ Runs all tests and generates a coverage report
test.cover: SHELL:=/bin/bash
test.cover: MIX_ENV=testMIX_ENV=test
test.cover:
	@mix coveralls.html

#🧪 test.watch: @ Runs and watches all test suites
test.watch: SHELL:=/bin/bash
test.watch: MIX_ENV=test
test.watch:
	@echo "🧪👁️  Watching all test suites..."
	@mix test.watch

#🧪 test.wip: @ Runs test suites that match the wip tag
test.wip: SHELL:=/bin/bash
test.wip: MIX_ENV=test
test.wip:
	@mix test --only wip

#🧪 test.wip.watch: @ Runs and watches test suites that match the wip tag
test.wip.watch: SHELL:=/bin/bash
test.wip.watch: MIX_ENV=test
test.wip.watch:
	@echo "🧪👁️  Watching test suites tagged with wip..."
	@mix test.watch --only wip

#📙 translations: @ Extract new untranslated phrases and merge translations to avaialble languages. This command uses fuzzy auto-generated transaltions, it generally needs a manual update to each language afterwards.
translations: SHELL:=/bin/bash
translations:
	@mix gettext.extract
	@mix gettext.merge priv/gettext --locale es
	@mix gettext.merge priv/gettext --locale en
