FROM debian:9-slim

ARG DEV_PACKAGES="autoconf libtool libpng-dev libfontconfig"

# Prepare base image
RUN set -xe ; \
    apt-get update -y ; \
    apt-get install -y curl git build-essential ${DEV_PACKAGES} supervisor ; \
    install -d /var/log/supervisor ; \
    bash -c 'curl -L https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | HOME=/root bash' ; \
    ln -sf /bin/bash /bin/sh ; \
    apt-get autoremove -y ; \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/*

CMD /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf

# ONBUILD COPY ./docker/supervisor.conf /etc/supervisor/conf.d/

# Configure standard environment
WORKDIR /root/app

# Configure node
ENV NODE_ENV production

# Invalidate cache if .nvmrc or .npmrc changes
ONBUILD COPY .nvmrc .nvmrc
ONBUILD COPY .npmrc .npmrc

# Make nvm install node specified in .nvmrc
ONBUILD ARG NPM_VERSION=6.1.0
ONBUILD RUN set -e ; \
    source /root/.nvm/nvm.sh 2>/dev/null || nvm install ; nvm alias default ; \
    [[ "${NPM_VERSION}" == "$(npm --version)" ]] || npm install -g npm@${NPM_VERSION} ; \
    nvm cache clear ; \
    ln -sf $(which node) /usr/bin/node ; \
    ln -sf $(which npm) /usr/bin/npm

# npm-shrinkwrap.json and package.json are used to bust the cache
# COPY npm-shrinkwrap.json /root/app/npm-shrinkwrap.json
ONBUILD COPY package.json package.json
ONBUILD COPY package-lock.json package-lock.json
ONBUILD RUN set -e ; \
    npm config set registry https://registry.npmjs.org/ ; \
    npm install ; \
    npm cache clean --force ; rm -rf /tmp/* /var/tmp/*

ONBUILD RUN npm ll --depth 0 || true

ONBUILD COPY . .
