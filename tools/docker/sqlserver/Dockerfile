FROM mcr.microsoft.com/azure-sql-edge

LABEL maintainer "Wheels Core Team"

# add sqlcmd from https://github.com/microsoft/go-sqlcmd
# we add this to /opt/mssql-tools/bin which completely overrides the
# sqlcmd from the base image. Read up on why we do this here:
# https://github.com/microsoft/go-sqlcmd/discussions/501#discussion-6088877
WORKDIR /opt/mssql-tools/bin
ENV GOSQLCMD_VERSION=v1.5.0
ARG TARGETPLATFORM
RUN case ${TARGETPLATFORM} in \
    "linux/amd64")  GOSQLCMD_ARCH=amd64 ;; \
    "linux/arm64")  GOSQLCMD_ARCH=arm64 ;; \
    *) echo "Unsupported platform: ${TARGETPLATFORM}"; exit 1 ;; \
    esac \
 && wget https://github.com/microsoft/go-sqlcmd/releases/download/${GOSQLCMD_VERSION}/sqlcmd-${GOSQLCMD_VERSION}-linux-${GOSQLCMD_ARCH}.tar.bz2 \
 && tar -xjf sqlcmd-${GOSQLCMD_VERSION}-linux-${GOSQLCMD_ARCH}.tar.bz2

# Set environment variables, not to have to write them with docker run command
ENV MSSQL_SA_PASSWORD "x!bsT8t60yo0cTVTPq"
ENV ACCEPT_EULA "Y"
ENV MSSQL_PID "Developer"

# Expose port 1433 in case accesing from other container
EXPOSE 1433

# Copy the initialization script into the container
COPY ./tools/docker/sqlserver/init-db.sh /usr/src/app/init-db.sh

CMD ["/bin/bash", "/usr/src/app/init-db.sh"]
