FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

ENV PORT 62023
ENV APP_DIR                 "/wheelsapp"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62023/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "./docker/adobe@2023/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
