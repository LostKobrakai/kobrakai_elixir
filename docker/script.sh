#!/usr/bin/env bash

set -e

cd /app

mkdir -p /app/rel/artifacts

# Install updated versions of hex/rebar
mix local.rebar --force
mix local.hex --if-missing --force

export MIX_ENV=prod

# Fetch deps and compile
mix deps.get --only $MIX_ENV
# Run an explicit clean to remove any build artifacts from the host
mix do clean, compile --force
# Build the release
mix release --path "/app/rel/artifacts/release.tar.gz"

exit 0