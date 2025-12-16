# Anvil local development node with BurnWithDigest contracts deployed
FROM ghcr.io/foundry-rs/foundry:latest

WORKDIR /app

# Copy foundry config first (needed for forge install)
COPY foundry.toml foundry.toml

# Install dependencies (need to init git for forge install to work)
RUN git init && forge install OpenZeppelin/openzeppelin-contracts

# Copy contract source files
COPY src/ src/
COPY script/ script/
COPY test/ test/

# Build contracts to verify they compile
RUN forge build

# Copy entrypoint (with executable permissions)
COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

# Expose Anvil RPC port
EXPOSE 8545

ENTRYPOINT ["/docker-entrypoint.sh"]
