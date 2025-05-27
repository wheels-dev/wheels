FROM container-registry.oracle.com/database/free:23.3.0.0

# Environment variables for Oracle setup
ENV ORACLE_PWD=Oracle123!
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_PDB=FREEPDB1

# Copy initialization scripts
COPY init-scripts /docker-entrypoint-initdb.d/

# Expose Oracle port
EXPOSE 1521 5500