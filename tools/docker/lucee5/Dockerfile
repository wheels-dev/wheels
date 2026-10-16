FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

# Install Lucee extensions (H2, Oracle) and SQLite JDBC driver in a single layer
# Each download retries: ext.lucee.org and Maven Central intermittently answer
# 5xx or 429, and one failed fetch fails the whole image build. ext.lucee.org is
# S3 behind CloudFront, which answers 403 (not 404) on an edge error as well as
# for a missing object, so 403 is retried too; these pinned URLs do exist.
# `wget -nv -S` logs each URL with the response status and headers on every attempt,
# so a failed build names the download and its status. (Without -S, wget does not
# print the status of an attempt it is going to retry.)
# The SQLite JDBC jar is checked against Maven Central's published SHA-256, so a
# damaged or substituted download fails the build instead of the tests.
RUN mkdir -p /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy \
 && wget -nv -S --tries=5 --waitretry=3 --retry-connrefused --retry-on-http-error=403,429,500,502,503,504 -O /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex \
      https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex \
 && wget -nv -S --tries=5 --waitretry=3 --retry-connrefused --retry-on-http-error=403,429,500,502,503,504 -O /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.oracle-21.8.0.0-ojdbc11.lex \
      https://ext.lucee.org/org.lucee.oracle-21.8.0.0-ojdbc11.lex \
 && mkdir -p /usr/local/lib/serverHome/WEB-INF/lucee-server/context/lib \
 && wget -nv -S --tries=5 --waitretry=3 --retry-connrefused --retry-on-http-error=403,429,500,502,503,504 -O /usr/local/lib/serverHome/WEB-INF/lucee-server/context/lib/sqlite-jdbc.jar \
      https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.50.3.0/sqlite-jdbc-3.50.3.0.jar \
 && echo "a3f53a2aa15ae9425a9e793bbe9c8e5288febeb4b65ef5c1a4e80d4c2045cf08  /usr/local/lib/serverHome/WEB-INF/lucee-server/context/lib/sqlite-jdbc.jar" | sha256sum -c -

# Install SQLite and create test database
RUN apt-get update -y && apt-get install -y --no-install-recommends sqlite3 libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && sqlite3 wheelstestdb.db "SELECT 1;"

ENV PORT 60005
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60005/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE
ENV BOX_SERVER_APP_CFENGINE "lucee@5.4.8+2"

# Set working directory
WORKDIR ${APP_DIR}

# Copy box.json for dependency management
COPY tools/docker/lucee5/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/lucee5/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
