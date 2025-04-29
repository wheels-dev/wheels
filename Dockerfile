FROM lucee/lucee:5.3

# Install CommandBox
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install CommandBox
RUN curl -fsSl https://downloads.ortussolutions.com/debs/gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/ortussolutions.gpg && \
    echo 'deb [trusted=yes] https://downloads.ortussolutions.com/debs/noarch /' > /etc/apt/sources.list.d/commandbox.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    commandbox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the application
COPY . .

# Make sure directory permissions are set correctly
RUN chmod -R 755 /app

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8080/ || exit 1

# Start Lucee
CMD ['catalina.sh', 'run']
