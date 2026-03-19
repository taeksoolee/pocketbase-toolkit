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

RUN apk add --no-cache ca-certificates

COPY --from=downloader /tmp/pocketbase/pocketbase /usr/local/bin/pocketbase

RUN chmod +x /usr/local/bin/pocketbase

WORKDIR /pb

EXPOSE 8090

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8090/api/health || exit 1

ENTRYPOINT ["pocketbase", "serve", "--http=0.0.0.0:8090"]
