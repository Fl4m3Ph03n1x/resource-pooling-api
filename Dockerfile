FROM elixir:1.10

# Install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

COPY . /
WORKDIR /

ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile
RUN mix release

EXPOSE 9091
ENV PORT=9091
ENV SHELL=/bin/bash

CMD ["_build/prod/rel/car_polling/bin/car_polling", "start"]