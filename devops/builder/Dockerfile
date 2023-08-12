# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20210902-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.12.3-erlang-23.3.4-debian-bullseye-20210902-slim
#
ARG BUILDER_IMAGE="hexpm/elixir:1.14.5-erlang-25.3.2.1-debian-bullseye-20230522"
ARG RUNNER_IMAGE="debian:bullseye-20210902-slim"
ARG SECRET_KEY_BASE
ARG UPLOADS_PATH

FROM ${BUILDER_IMAGE} as builder

ENV ASDF_VERSION v0.9.0
ENV NODE_VERSION 16.13.1

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl && \
    apt-get clean && rm -f /var/lib/apt/lists/*_* && \
    bash && \
    PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH" && \
    echo "PATH=$HOME/.asdf/bin:$HOME/.asdf/shims:$PATH" >> ~/.bashrc && \
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION} && \
    asdf plugin-add nodejs && \
    asdf install nodejs ${NODE_VERSION} && \
    asdf global nodejs ${NODE_VERSION}

SHELL ["/bin/bash", "--login", "-c"]

RUN asdf --version
RUN npm --version
RUN node --version

# prepare build dir
WORKDIR "/opt/app"

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV UPLOADS_PATH=${UPLOADS_PATH}
ENV RECAPTCHA_PUBLIC_KEY=${RECAPTCHA_PUBLIC_KEY}
ENV RECAPTCHA_SECRET=${RECAPTCHA_SECRET}

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Compile the release
COPY priv priv
COPY lib lib

RUN mix compile

# Note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/opt/app"
COPY devops/builder/entrypoint.sh .
RUN chmod +x entrypoint.sh
RUN chown nobody /opt/app

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /opt/app/_build/prod/rel/livedj .

USER nobody

CMD /opt/app/entrypoint.sh start
