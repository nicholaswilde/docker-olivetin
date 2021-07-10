FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as base
ARG VERSION
WORKDIR /tmp
COPY ./checksums.txt .
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    wget=1.21.1-r1

FROM base as base_amd64
ARG VERSION
ARG FILENAME="OliveTin-${VERSION}-linux-amd64.tar.gz"
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/OliveTin/OliveTin/releases/download/${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/OliveTin

FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as build_amd64
COPY --from=base_amd64 /app/OliveTin /usr/bin/OliveTin
COPY --from=base_amd64 /app/webui /var/www/olivetin/

#########################

FROM base as base_arm64
ARG VERSION
ARG FILENAME="OliveTin-${VERSION}-linux-arm64.tar.gz"
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/OliveTin/OliveTin/releases/download/${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/OliveTin

FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as build_arm64
COPY --from=base_arm64 /app/OliveTin /usr/bin/OliveTin
COPY --from=base_arm64 /app/webui /var/www/olivetin/

#########################

FROM base as base_arm
ARG VERSION
ARG FILENAME="OliveTin-${VERSION}-linux-arm.tar.gz"
WORKDIR /tmp
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/OliveTin/OliveTin/releases/download/${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/OliveTin

FROM ghcr.io/linuxserver/baseimage-alpine:3.14 as build_arm
COPY --from=base_arm /app/OliveTin /usr/bin/OliveTin
COPY --from=base_arm /app/webui /var/www/olivetin/

########################

# hadolint ignore=DL3006
FROM build_${TARGETARCH}
ARG BUILD_DATE
ARG VERSION
# hadolint ignore=DL3048
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"
RUN \
  echo "**** install packages ****" && \
  apk add --no-cache \
    iputils=20210202-r0 && \
  echo "**** cleanup ****" && \
  rm -rf /tmp/*

# copy local files
COPY root/ /

# copy default config file
COPY config.yaml /defaults

# ports and volumes
EXPOSE 1337
VOLUME /config
