# Dockerfile
FROM alpine:3.20

# Install ZFS utilities
RUN apk add --no-cache zfs

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
