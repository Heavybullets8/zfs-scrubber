FROM alpine:3.20

RUN apk add --no-cache zfs bash curl

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
