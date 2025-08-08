FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

ENV PORT 60001
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60001/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/cfwheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# Set working directory
WORKDIR ${APP_DIR}

# Copy files
COPY templates/base/src ${APP_DIR}
COPY core/src/wheels ${APP_DIR}/vendor/wheels
COPY tests ${APP_DIR}/tests
COPY tools/docker/boxlang/box.json ${APP_DIR}/box.json
COPY tools/docker/boxlang/CFConfig.json ${APP_DIR}/CFConfig.json

COPY tools/docker/boxlang/server.json ${APP_DIR}/server.json
COPY tools/docker/boxlang/settings.cfm ${APP_DIR}/config/settings.cfm
# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
