ARG PHP_VERSION=7.4
FROM ghcr.io/friendsofshopware/platform-plugin-dev-base:${PHP_VERSION}

ARG SHOPWARE_VERSION=dev-master
ARG TEMPLATE_REPOSITORY=https://github.com/shopware/production

ENV SHOPWARE_BUILD_DIR /opt/shopware

RUN \
  if echo "${SHOPWARE_VERSION}" | grep -q '^6.4.*'; then \
      apk add --no-cache --repository="https://dl-cdn.alpinelinux.org/alpine/v3.16/main" 'nodejs=16.17.1-r0' 'npm=8.10.0-r0'; \
  else \
      apk add --no-cache npm; \
  fi

RUN \
    start-mysql && \
    mysql -e "CREATE DATABASE shopware" && \
    mysqladmin --user=root password 'root' && \
    mkdir -p /opt/shopware && \
    git clone -b ${SHOPWARE_VERSION} --depth 1 "${TEMPLATE_REPOSITORY}" "${SHOPWARE_BUILD_DIR}" && \
    cd "${SHOPWARE_BUILD_DIR}" && \
        composer install --no-interaction -o && \
        APP_URL="http://localhost" php bin/console system:setup --database-url=mysql://root:root@localhost:3306/shopware --generate-jwt-keys -nq && \
        php bin/console system:install -fnq --create-database && \
        composer clearcache && \
        rm -rf "${SHOPWARE_BUILD_DIR}/custom/plugins" && \
        mkdir -p /plugins && ln -s /plugins "${SHOPWARE_BUILD_DIR}/custom/plugins" && \
        rm -rf "${SHOPWARE_BUILD_DIR}/custom/apps" && \
        mkdir -p /apps && ln -s /apps "${SHOPWARE_BUILD_DIR}/custom/apps"

VOLUME /plugins
WORKDIR /opt/shopware
