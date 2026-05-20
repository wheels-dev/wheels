FROM ortussolutions/commandbox:latest@sha256:1f180edf899d1db7fc906835e20c12ed18a93db2c2c1053ac5cace2f28626da0

LABEL maintainer "Wheels Core Team"

# Install SQLite and create test database
RUN apt-get update -y && apt-get install -y --no-install-recommends sqlite3 libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && sqlite3 wheelstestdb.db "SELECT 1;"

ENV PORT 62023
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62023/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE
ENV BOX_SERVER_APP_CFENGINE "adobe@2023.0.11+330706"

# Set working directory
WORKDIR ${APP_DIR}

# Copy box.json for dependency management
COPY tools/docker/adobe2023/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/adobe2023/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
