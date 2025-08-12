FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

#Add the H2 extension
ADD https://ext.lucee.org/org.lucee.h2-2.1.214.0001L.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.h2-2.1.214.0001L.lex

#Add the Oracle extension
ADD https://ext.lucee.org/org.lucee.oracle-21.8.0.0-ojdbc11.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.lucee.oracle-21.8.0.0-ojdbc11.lex

ENV PORT 60005
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60005/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/cfwheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE
ENV BOX_SERVER_APP_CFENGINE "lucee@5"

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
