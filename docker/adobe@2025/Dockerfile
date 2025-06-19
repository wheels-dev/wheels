FROM ortussolutions/commandbox:jdk17

LABEL maintainer "Wheels Core Team"

ENV PORT 62025
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62025/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "./docker/adobe@2025/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh