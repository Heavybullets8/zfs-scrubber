FROM alpine:3.24

RUN apk add --no-cache cosign crane bash curl libuuid libblkid

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
