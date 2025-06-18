FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

#Add the H2 extension
ADD https://ext.lucee.org/org.h2-1.3.172.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.h2-1.3.172.lex

ENV PORT 60007
ENV APP_DIR                 "/cfwheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60007/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/cfwheels-test-suite/docker/lucee@7/CFConfig.json"
ENV BOX_SERVER_PROFILE      "none"
ENV BOX_INSTALL             TRUE

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh