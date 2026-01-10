FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

#Add the H2 extension
# ADD https://ext.lucee.org/org.h2-1.3.172.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.h2-1.3.172.lex
ADD https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex

#Add the Oracle extension
ADD https://ext.lucee.org/org.lucee.oracle-21.8.0.0-ojdbc11.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.oracle-21.8.0.0-ojdbc11.lex

#Add sqltie jdbc driver
RUN mkdir -p /usr/local/lib/serverHome/WEB-INF/lucee-server/context/lib \
 && wget -O /usr/local/lib/serverHome/WEB-INF/lucee-server/context/lib/sqlite-jdbc.jar \
    https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.50.3.0/sqlite-jdbc-3.50.3.0.jar

#Add Sqlite
RUN apt update -y && apt install -y sqlite3 libsqlite3-dev
RUN pwd
RUN sqlite3 wheelstestdb.db

ENV PORT 60007
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60007/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE
ENV BOX_SERVER_APP_CFENGINE "lucee@7"

# Set working directory
WORKDIR ${APP_DIR}

# Copy box.json for dependency management
COPY tools/docker/lucee7/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/lucee7/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
