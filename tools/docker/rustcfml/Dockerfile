# Stage 1: Build RustCFML from source
FROM rust:1.78-bookworm AS builder

ARG RUSTCFML_VERSION=v0.9.1

RUN apt-get update && apt-get install -y \
    git pkg-config libssl-dev libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${RUSTCFML_VERSION} \
    https://github.com/pixl8/RustCFML.git /build

WORKDIR /build
RUN cargo build --release --features "database,xml"

# Stage 2: Minimal runtime image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    sqlite3 libsqlite3-0 libssl3 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/rustcfml /usr/local/bin/rustcfml

RUN sqlite3 /app/wheelstestdb.db "SELECT 1;" \
    && sqlite3 /app/wheelstestdb_tenant_b.db "SELECT 1;"

ENV PORT=60100
WORKDIR /wheels-test-suite

EXPOSE ${PORT}

CMD ["rustcfml", "--serve", "public", "--port", "60100"]
