# This ARG has to be at the top, otherwise the docker daemon does not known what to do
ARG BUILDER_IMAGE=docker.io/library/golang:1-alpine
ARG RUNTIME_IMAGE=docker.io/library/alpine:3
ARG VERSION=
ARG TAG_VERSION=
ARG GO_VERSION=
ARG SRC_REPO=github.com/tsenart/vegeta
ARG BIN=vegeta
ARG APP=vegeta
ARG GID=1001
ARG UID=10001

FROM --platform=${BUILDPLATFORM} ${BUILDER_IMAGE} AS builder

ARG GO_VERSION
ARG SRC_REPO
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG BIN

RUN set -eux \
    && apk --no-cache add cmake g++ make unzip curl git

WORKDIR ${GOPATH}/src/${SRC_REPO}

RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  \
            GOOS=linux GOARCH=amd64 \
            go install ${SRC_REPO}@${GO_VERSION} \
            && cp -p /go/bin/linux_amd64/${BIN} /go/bin/${BIN} || test -x /go/bin/${BIN} \
              ;; \
         "linux/arm64" | "linux/arm64/v8")  \
            GOOS=linux GOARCH=arm64 \
            go install ${SRC_REPO}@${GO_VERSION} \
            && cp -p /go/bin/linux_arm64/${BIN} /go/bin/${BIN} \
              ;; \
         "linux/arm/v7")  \
            GOOS=linux GOARCH=arm GOARM=7 \
            go install ${SRC_REPO}@${GO_VERSION} \
            && cp -p /go/bin/linux_arm/${BIN} /go/bin/${BIN} \
             ;; \
    esac

FROM ${RUNTIME_IMAGE}

ARG BIN
ARG APP
ARG GID
ARG UID

COPY --from=builder /go/bin/${BIN} /usr/bin/${APP}

RUN set -eux \
    && apk --no-cache add --virtual build-dependencies unzip curl openssl git jq tzdata tree netcat-openbsd bash

RUN cp /usr/share/zoneinfo/Japan /etc/localtime

RUN addgroup -g ${GID} ${APP} && \
  adduser -S -D -H -s /sbin/nologin -u ${UID} -G ${APP} ${APP}

USER ${APP}:${APP}

ENTRYPOINT /usr/bin/${APP}
