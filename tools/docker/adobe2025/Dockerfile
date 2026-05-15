FROM ortussolutions/commandbox:jdk21@sha256:d65126caeb6c80c115d4cc93f9b9db88697c4fe2aa4ca83ea9a36dadc62c02c1

LABEL maintainer "Wheels Core Team"

# Install SQLite and create test database
RUN apt-get update -y && apt-get install -y --no-install-recommends sqlite3 libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && sqlite3 wheelstestdb.db "SELECT 1;"

ENV PORT 62025
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62025/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE
ENV BOX_SERVER_APP_CFENGINE "adobe@2025.0.06+331564"

# Set working directory
WORKDIR ${APP_DIR}

# Copy box.json for dependency management
COPY tools/docker/adobe2025/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/adobe2025/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
