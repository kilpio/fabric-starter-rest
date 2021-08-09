ARG DOCKER_REGISTRY
ARG FABRIC_STARTER_VERSION
ARG FABRIC_STARTER_REPOSITORY

FROM ${DOCKER_REGISTRY:-docker.io}/${FABRIC_STARTER_REPOSITORY:-olegabu}/fabric-tools-extended:${FABRIC_STARTER_VERSION:-latest}

MAINTAINER ${FABRIC_STARTER_REPOSITORY:-olegabu}

FROM ${DOCKER_REGISTRY:-docker.io}/olegabu/fabric-tools-extended:${FABRIC_STARTER_VERSION:-baas-test} as fabrictools
FROM ${DOCKER_REGISTRY:-docker.io}/olegabu/fabric-starter-rest:${FABRIC_STARTER_VERSION:-baas-test}-base as external_admin_webapp_false

LABEL MAINTAINER=olegabu

## install dependencies
COPY "package.json" .
COPY gost-deps/crypto-gost/package.json ./gost-deps/crypto-gost/
COPY gost-deps/fabric-client/package.json ./gost-deps/fabric-client/
COPY gost-deps/fabric-cryptosuite-gost/package.json ./gost-deps/fabric-cryptosuite-gost/

RUN apt-get update && apt-get install python make  \
&& npm install && npm rebuild && npm cache rm --force \
&& apt-get remove -y python make && apt-get purge


RUN git clone https://github.com/olegabu/fabric-starter-admin-web.git --branch stable --depth 1 admin && npm install aurelia-cli@0.35.1 -g \
&& cd admin && npm install && au build --env prod && rm -rf node_modules

# add project files (see .dockerignore for a list of excluded files)
COPY . .

# if set USE_EXTERNAL_ADMIN_WEBAPP=true then this layer is invoked, so add external admin webapp package
FROM external_admin_webapp_false as external_admin_webapp_true
ONBUILD ADD admin-webapp.tgz /external-admin
ONBUILD RUN rm admin-webapp.tgz

# previous layer will be invoked if USE_EXTERNAL_ADMIN_WEBAPP=true
FROM external_admin_webapp_${USE_EXTERNAL_ADMIN_WEBAPP:-false}

# and copy external admin instead of built-in one
RUN if [ -d "/external-admin" ]; then \
        rm -rf admin/node-modules; \
        mkdir -p webapps/admin-old; \
        cp -r admin/* webapps/admin-old; \
        rm -rf admin; \
        cp -r /external-admin/ /usr/src/app/admin; \
        rm -rf /external-admin; \
    fi;

COPY --from=fabrictools /etc/hyperledger/templates /usr/src/app/templates
COPY --from=fabrictools /etc/hyperledger/container-scripts /usr/src/app/container-scripts
COPY --from=fabrictools /etc/hyperledger/docker-compose*.yaml /usr/src/app/


EXPOSE 3000
CMD [ "npm", "start" ]
