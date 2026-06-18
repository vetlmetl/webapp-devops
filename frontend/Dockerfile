# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

RUN NODE_ENV=production VUE_APP_API_URL=/api npm run build

# ---- Final Stage ----
# nginx-unprivileged runs as UID 101 (nginx) and binds to a non-privileged
# port (8080), so it works in any K8s runtime without needing
# net.ipv4.ip_unprivileged_port_start tweaks or NET_BIND_SERVICE.
FROM nginxinc/nginx-unprivileged:alpine

# Switch to root for setup, then drop back to the unprivileged user.
USER root

# Copy built application from builder to momo-store subdirectory
COPY --from=builder /app/dist /usr/share/nginx/html/momo-store

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY security-headers.conf /etc/nginx/security-headers.conf

# Change ownership of nginx cache and runtime directories
RUN mkdir -p /var/cache/nginx /var/run/nginx /var/log/nginx && \
    chown -R nginx:nginx /var/cache/nginx /var/run/nginx /usr/share/nginx/html /var/log/nginx

# Switch back to the non-root user (UID 101)
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/momo-store/ || exit 1

CMD ["nginx", "-g", "daemon off;"]

