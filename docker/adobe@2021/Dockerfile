FROM ortussolutions/commandbox:latest

LABEL maintainer "CFWheels Core Team"

ENV PORT 62021
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62021/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "./docker/adobe@2021/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# Copy Oracle JDBC driver
COPY docker/adobe@2021/lib ${APP_DIR}/docker/adobe@2021/lib

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
