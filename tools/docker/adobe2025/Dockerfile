FROM ortussolutions/commandbox:jdk21

LABEL maintainer "Wheels Core Team"

#Add sqltie jdbc driver
RUN mkdir -p /wheels-test-suite/.engine/adobe2025/WEB-INF/cfusion/lib \
 && wget -O /wheels-test-suite/.engine/adobe2025/WEB-INF/cfusion/lib/sqlite-jdbc.jar \
    https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.50.3.0/sqlite-jdbc-3.50.3.0.jar

#Add Sqlite
RUN apt update -y && apt install -y sqlite3 libsqlite3-dev
RUN pwd
RUN sqlite3 wheelstestdb.db

ENV PORT 62025
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62025/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

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
