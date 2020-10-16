ARG DOCKER_REGISTRY
ARG FABRIC_STARTER_VERSION
FROM ${DOCKER_REGISTRY:-docker.io}/olegabu/fabric-tools-extended:${FABRIC_STARTER_VERSION:-latest}

MAINTAINER olegabu

# Create app directory
WORKDIR /usr/src/app

RUN apt-get remove docker docker-engine docker.io containerd runc || true
RUN apt-get update && apt-get install -y python make \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

RUN  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

RUN sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

## install dependencies
# COPY ["package.json", "package-lock.json"] .
COPY gost-deps ./gost-deps
COPY "package.json" .

#RUN apt-get update && apt-get install python make  \
RUN npm install && npm rebuild && npm cache rm --force \
&& apt-get remove -y python make && apt-get purge


RUN git clone https://github.com/olegabu/fabric-starter-admin-web.git --branch stable --depth 1 admin && npm install aurelia-cli@0.35.1 -g \
&& cd admin && npm install && au build --env prod && rm -rf node_modules

# add project files (see .dockerignore for a list of excluded files)
COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]
