# Server Site Dockerfile - Static Player Guide
# Build: docker build -f containers/server-site/Dockerfile -t minecraft-server-site:latest .

FROM nginx:alpine

# Copy static HTML files
COPY containers/server-site/public/ /usr/share/nginx/html/

# Copy nginx configuration
COPY containers/server-site/nginx.conf /etc/nginx/conf.d/default.conf

# Create data directory mount point
RUN mkdir -p /usr/share/nginx/html/data

# Expose port for static site
EXPOSE 80

# Nginx runs by default, no CMD needed
