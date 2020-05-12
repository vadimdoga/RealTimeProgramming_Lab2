FROM elixir:1.10.2 as build

ARG APP_NAME=elixir-lab-2

ARG APP_VSN=0.1.0

ARG SKIP_PHOENIX=false

ARG MIX_ENV=prod

RUN mix local.hex --force
RUN mix local.rebar --force

COPY . .

RUN mix do deps.get, deps.compile, compile

CMD ["mix", "run", "--no-halt"]


