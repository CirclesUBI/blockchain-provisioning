FROM ubuntu:16.04

# Base packages

RUN apt-get update && apt-get install -y \
  git \
  wget

# Install app dependencies

RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb

RUN apt-get update && apt-get install -y \
  elixir \
  esl-erlang \
  inotify-tools \
  nodejs \
  postgresql

# Set locale (required by mix)

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install app

RUN git clone https://github.com/poanetwork/poa-explorer.git
WORKDIR /poa-explorer

RUN cp apps/explorer/config/dev.secret.exs.example apps/explorer/config/dev.secret.exs
RUN cp apps/explorer_web/config/dev.secret.exs.example apps/explorer_web/config/dev.secret.exs

RUN mix local.hex --force
RUN mix do deps.get, local.rebar, deps.compile, compile

ENTRYPOINT mix phx.server
