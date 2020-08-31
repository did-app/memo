FROM rust:1.46.0 AS build

RUN cargo install diesel_cli --no-default-features --features postgres

FROM gleamlang/gleam:0.11.1

COPY --from=build /usr/local/cargo/bin/diesel /bin
RUN diesel --version

# NOTE the WORKDIR should not be the users home dir as the will copy container cookie into host machine
WORKDIR /opt/app
RUN mix local.hex --force && mix local.rebar --force

# --------
# FIXME revert to midas once 0.11.0 stable

# FROM gleamlang/gleam:0.11.0-rc1
#
# # NOTE these two should not be needed if using the midas container
# WORKDIR /opt/app
# RUN mix local.hex --force && mix local.rebar --force

# ------------

COPY . .
RUN mix deps.get
# NOTE there is a bug which means gleam_otp is not compiling properly
RUN gleam build && mix compile
# Unsure why this step is necessay with compilation orders with Gleam + Mix
RUN mix test --no-start --exclude test

CMD ["./bin/start"]
