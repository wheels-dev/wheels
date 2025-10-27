FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

#Add Sqlite
RUN apt update -y && apt install -y sqlite3 libsqlite3-dev
RUN pwd
RUN sqlite3 wheelstestdb.db

ENV PORT 62023
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62023/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

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
