FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

ENV PORT 62021
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:62021/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/cfwheels-test-suite/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# Set working directory
WORKDIR ${APP_DIR}

RUN apt update && apt install wget -y
RUN wget https://download.oracle.com/otn-pub/otn_software/jdbc/1927/ojdbc10.jar
RUN mkdir -p /cfwheels-test-suite/.engine/adobe2021/WEB-INF/lib && \
    cp ojdbc10.jar /cfwheels-test-suite/.engine/adobe2021/WEB-INF/lib/

# Copy box.json for dependency management
COPY tools/docker/adobe2021/box.json ${APP_DIR}/box.json

# Copy CFConfig
COPY tools/docker/adobe2021/CFConfig.json ${APP_DIR}/CFConfig.json

# Install dependencies
RUN box install

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
