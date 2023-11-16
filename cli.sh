#!/bin/bash

set -e

CLI="$0"
COMPOSE_VERSION="v2.11.2"
init(){
    echo "Is current directory: " $(pwd)
    read -p "Confirm[y/n]: " confirm
    if [[ "$confirm" == ""  || "$confirm" == "n" ]]; then
        exit 1
    fi
    mkdir -p configs
    mkdir -p certs
    mkdir -p template
    echo "Load: TraefikConfigs.yaml"
    test -f "TraefikConfigs.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/TraefikConfigs.yaml -o TraefikConfigs.yaml
    echo "Load: traefik-stack.yaml"
    test -f "traefik-stack.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/traefik-stack.yaml -o traefik-stack.yaml
    echo "Load: portainer-agant-stack.yaml"
    test -f "portainer-agant-stack.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/portainer-agant-stack.yaml -o portainer-agant-stack.yaml
    echo "Load: configs/dashboad.yaml"
    test -f "configs/dashboad.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/configs/dashboad.yaml -o configs/dashboad.yaml
    echo "Load: configs/portainer.yaml"
    test -f "configs/portainer.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/configs/portainer.yaml -o configs/portainer.yaml
    echo "Load: configs/certs.yaml"
    test -f "configs/certs.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/configs/certs.yaml -o configs/certs.yaml
    echo "Load: template/sample.yaml"
    test -f "template/sample.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/template/sample.yaml -o template/sample.yaml
    echo "Load: template/filebrowser4traefik.yaml"
    test -f "template/filebrowser4traefik.yaml" || curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/template/filebrowser4traefik.yaml -o template/filebrowser4traefik.yaml
    
    config
    mkdir -p /var/log/traefik/ || echo "Plaese Run: sudo mkdir -p /var/log/traefik/"
}



pull_traefik(){
    docker pull traefik:latest
    docker pull vegardit/traefik-logrotate:latest
}

pull_portainer(){
    docker pull portainer/portainer-ce:latest
    docker pull portainer/agent:latest
}

deploy(){
    if [ -f "domain.txt" ]; then
        echo "docker stack deploay traefik"
        pull_traefik
        docker stack deploy -c traefik-stack.yaml traefik
        read -p "Deploy Portainter?[y/n]" confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            deploy-portainer
        fi

        read -p "Deploy Filebrowser?[y/n]" confirm
        if [[ "$confirm" == "y"  || "$confirm" == "Y" ]]; then
            deploy-filebrowser
        fi
    fi
    exit 0
}

deploy-portainer(){
    if [ -f "domain.txt" ]; then
        pull_portainer
        echo "docker stack deploy portainer "
        docker stack deploy -c portainer-agant-stack.yaml portainer
    fi
    exit 0
}

config(){
    docker network create --attachable --driver=overlay proxy || echo "docker network with name 'proxy' already exists"
    echo "Setup treafik domain config"
    DOMAIN=$(cat "./domain.txt" || echo "localhost")
    read -p "Domain or IP (default: ${DOMAIN}): " DOMAIN 
    test -n "${DOMAIN}" || DOMAIN=$(cat "./domain.txt")
    echo "Your server is domain: ${DOMAIN}"
    echo "Setup to traefik configs"
    echo "${DOMAIN}" > domain.txt
    test -n "${DOMAIN}" || (echo "Domain/IP empty. Please run: ${CLI} config"; exit 1)
    sed -i "s/__DOMAIN__/${DOMAIN}/g" configs/dashboad.yaml
    sed -i "s/__DOMAIN__/${DOMAIN}/g" configs/portainer.yaml
    exit 0
}


cli-update(){
    /bin/bash -c  "curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/cli.sh -o ${CLI} && chmod +x ${CLI}"
    exit 0
}


add(){
    test -f "./domain.txt" || (echo "Plaese run:  ${CLI} config" exit 0)
    DOMAIN=$(cat "./domain.txt")
    test -n "${DOMAIN}" || (echo "Domain or IP not empty."; exit 1)
    read -p "ServiceName: " SERVICE
    test -n "${SERVICE}" || (echo "ServiceName not empty."; exit 1)
    if [ -f "configs/${SERVICE}.yaml" ]; then
        echo "Service: ${SERVICE} is exist. Overwrite service [y/n]: "
        read ok
        test "$ok" = "y" && echo "Overwrite service ${SERVICE}" || exit 1
    fi

    read -p "PathPrefix(default: /): " PATHPREFIX
    test -n "${PATHPREFIX}" || PATHPREFIX="/"

    read -p "Service URL (default: http://${SERVICE}): " SERVICE_URL
    test -n "${SERVICE_URL}" || SERVICE_URL="http://${SERVICE})"

    echo "Service: \`${SERVICE}\` is set rule: Host(\`${DOMAIN}\`) && PathPrefix(\`${PATHPREFIX}\`)"
    echo "Service URL Listener: ${SERVICE_URL}"


    echo "Use template template/sample.yaml"
    cp template/sample.yaml "/tmp/${SERVICE}.yaml"

    sed -i "s/__DOMAIN__/${DOMAIN}/g" "/tmp/${SERVICE}.yaml"
    sed -i "s/__SERVICE__/${SERVICE}/g"  "/tmp/${SERVICE}.yaml"

    REGEXPATH=$(echo "$SERVICE_URL" | sed -e 's/\//__ST__/g')
    sed -i "s/__SERVICE_URL__/${REGEXPATH}/g"  "/tmp/${SERVICE}.yaml"
    sed -i "s/__ST__/\\//g"  "/tmp/${SERVICE}.yaml"

    REGEXPATH=$(echo "$PATHPREFIX" | sed -e 's/\//__ST__/g')
    sed -i "s/__PATHPREFIX__/${REGEXPATH}/g"  "/tmp/${SERVICE}.yaml"
    sed -i "s/__ST__/\\//g"  "/tmp/${SERVICE}.yaml"
    mv "/tmp/${SERVICE}.yaml" "configs/${SERVICE}.yaml"
    echo "Success!!!"

    ping ${DOMAIN} -c 5
    echo "Test: curl -I -k  https://${DOMAIN}${PATHPREFIX}"
    curl -I -k  "https://${DOMAIN}${PATHPREFIX}"
    exit 0
}

env(){
    SERVICE_NAME=filebrowser4traefik
    DOMAIN=$(cat "./domain.txt")
    BASE_URL=/filebrowser4traefik
    VOLUME_MOUNT=$(pwd)
    PUID=$(id -u)
    PGID=$(id -u)
    echo "DOMAIN: ${DOMAIN}"
    echo "BASE_URL: ${BASE_URL}"
    echo "VOLUME_MOUNT: ${VOLUME_MOUNT}"
    echo "PUID: ${PUID}, PGID: ${PGID}"
}

deploy-filebrowser(){
    env
    SERVICE_NAME=filebrowser4traefik \
    DOMAIN=$(cat "./domain.txt") \
    BASE_URL=/filebrowser4traefik \
    VOLUME_MOUNT=$(pwd) \
    PUID=$(id -u) \
    PGID=$(id -u) \
    docker compose -f template/filebrowser4traefik.yaml config > filebrowser-stack.yaml
    echo "# $(cat filebrowser-stack.yaml)" > filebrowser-stack.yaml
    echo "Start deploy filebrowser-stack.yaml"
    docker stack deploy -c filebrowser-stack.yaml traefik
    exit 0
}

$@

echo "command shell script helper for create reverse-proxy with treafik"
echo "Documentation: https://doc.traefik.io/traefik/"
echo "Treafik config route direcotry: ./configs"
echo ""
echo "${CLI} [command]"
echo "Commands: "
echo "  init                Init project and set configulation"
echo "  config              Set config porject"
echo "  up                  Deploy traefik with docker-compose (docker-compose.yaml)"
echo "  deploy              Deploy traefik with swarm mode (traefik-stack.yaml)"
echo "  deploy-portainer    Deploy portainer with swarm mode (portainer-agant-stack.yaml)"
echo "  deploy-filebrowser  Create&Deploy filebrowser with swarm mode (filebrowser-stack.yaml)"
echo "  add                 Add new route in traefik with template (template/sample.yaml)"
echo ""
echo "Optional tools:"
echo "  install-compose     Install docker-compose version ${COMPOSE_VERSION}"
echo "  cli-update          update '${CLI}' helper"
echo ""
