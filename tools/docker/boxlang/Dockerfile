FROM ortussolutions/commandbox:latest

LABEL maintainer "Wheels Core Team"

#Add Sqlite
RUN apt update -y && apt install -y sqlite3 libsqlite3-dev
RUN pwd
RUN sqlite3 wheelstestdb.db

ENV PORT 60001
ENV APP_DIR                 "/wheels-test-suite"
ENV HEALTHCHECK_URI         "http://127.0.0.1:60001/"
ENV ENV_MODE                "remote"
ENV BOX_SERVER_CFCONFIGFILE "/wheels-test-suite/CFConfig.json"
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

# Pre-install JDK with retry to avoid transient Adoptium API failures
RUN for i in 1 2 3; do \
        echo "Attempt $i: Installing OpenJDK 21..."; \
        box install java:openjdk21 && break; \
        echo "Attempt $i failed, waiting 10s..."; \
        sleep 10; \
    done

# Start once to create BoxLang engine
RUN box server start --background && sleep 10 && box server stop

# Move bx-* modules if engine modules dir exists
RUN if [ -d ".engine/boxlang/WEB-INF/boxlang/modules" ]; then \
        echo "Moving bx-* modules"; \
        mv bx-* .engine/boxlang/WEB-INF/boxlang/modules/ 2>/dev/null || true; \
    else \
        echo "Engine modules directory missing"; \
    fi

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh
