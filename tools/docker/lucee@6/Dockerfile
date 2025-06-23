FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

# Add the H2 extension
ADD https://ext.lucee.org/org.h2-1.3.172.lex /usr/local/lib/serverHome/WEB-INF/lucee-server/deploy/org.h2-1.3.172.lex

ENV PORT 60006
ENV APP_DIR "/wheelsapp"
ENV HEALTHCHECK_URI "http://127.0.0.1:60006/"
ENV BOX_SERVER_PROFILE "none"

# Set working directory
WORKDIR ${APP_DIR}

# Copy main box.json for dependency management
COPY box.json ${APP_DIR}/

# Copy the server.json from the Docker directory
COPY tools/docker/lucee@6/server.json ${APP_DIR}/

# Install dependencies using box install
RUN cd ${APP_DIR} && box install --verbose --force

# Warm up the server
RUN ${BUILD_DIR}/util/warmup-server.sh || true