ARG PB_VERSION=0.22.4

FROM alpine:3.19 AS downloader

ARG PB_VERSION
ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache curl unzip && \
    curl -fsSL \
      "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_${TARGETOS}_${TARGETARCH}.zip" \
      -o /tmp/pocketbase.zip && \
    unzip /tmp/pocketbase.zip -d /tmp/pocketbase

FROM alpine:3.19

RUN apk add --no-cache ca-certificates curl

COPY --from=downloader /tmp/pocketbase/pocketbase /usr/local/bin/pocketbase

RUN chmod +x /usr/local/bin/pocketbase

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /pb

ARG PB_HOST_PORT=8090
EXPOSE ${PB_HOST_PORT}

ENTRYPOINT ["/entrypoint.sh"]
