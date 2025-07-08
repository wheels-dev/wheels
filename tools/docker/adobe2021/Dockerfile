FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

ENV PORT 8080
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:8080/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/cfwheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# Set working directory
WORKDIR ${APP_DIR}

# Copy box.json for dependency management
COPY tools/docker/adobe2021/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/adobe2021/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
