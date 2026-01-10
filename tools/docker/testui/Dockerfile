FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all project files
COPY . .

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:stable-alpine

# Install packages needed for Docker socket access
RUN apk add --no-cache shadow coreutils curl

# Copy built files from the build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY proxy_buffer_size.conf /etc/nginx/conf.d/

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Make entrypoint executable
RUN chmod +x /docker-entrypoint.sh

# Expose port
EXPOSE 80

# Use our custom entrypoint script
ENTRYPOINT ["/docker-entrypoint.sh"]