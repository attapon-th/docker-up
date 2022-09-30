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
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/docker-compose.yaml -o docker-compose.yaml
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/traefik-stack.yaml -o traefik-stack.yaml
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/portainer-agant-stack.yaml -o portainer-agant-stack.yaml
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/configs/dashboad.yaml -o configs/dashboad.yaml
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/configs/portainer.yaml -o configs/portainer.yaml
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/template/sample.yaml -o template/sample.yaml
    config
}

up(){
    if [ -f "domain.txt" ]; then
        echo "docker compose up -d traefik"
        docker stack deploy -c traefik-stack.yaml traefik
        read -p "Deploy Portainter?[y/n]" confirm
        if [[ "$confirm" == ""  || "$confirm" == "n" ]]; then
            exit 1
        fi
        deploy-portainer
    fi
    exit 0
}


deploy(){
    if [ -f "domain.txt" ]; then
        echo "docker stack deploay traefik"
        docker stack deploy -c traefik-stack.yaml traefik
        read -p "Deploy Portainter?[y/n]" confirm
        if [[ "$confirm" == ""  || "$confirm" == "n" ]]; then
            exit 1
        fi
        deploy-portainer
    fi
    exit 0
}

deploy-portainer(){
    if [ -f "domain.txt" ]; then
        echo "docker stack deploy portainer "
        docker stack deploy -c portainer-agant-stack.yaml portainer
    fi
    exit 0
}

config(){
    docker network create --attachable --driver=overlay proxy || echo "docker network with name 'proxy' already exists"
    echo "Setup treafik domain config"
    read -p "Domain or IP (default: localhost): " DOMAIN 
    test -n "${DOMAIN}" || DOMAIN="localhost"
    echo "Your server is domain: ${DOMAIN}"
    echo "Setup to traefik configs"
    echo "${DOMAIN}" > domain.txt
    test -n "${DOMAIN}" || (echo "Domain/IP empty. Please run: ${CLI} config"; exit 1)
    sed -i "s/__DOMAIN__/${DOMAIN}/g" configs/dashboad.yaml
    sed -i "s/__DOMAIN__/${DOMAIN}/g" configs/portainer.yaml
    exit 0
}

install-compose(){
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    docker compose version
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



$@

echo "command shell script helper for create reverse-proxy with treafik"
echo "Documentation: https://doc.traefik.io/traefik/"
echo "Treafik config route direcotry: ./configs"
echo ""
echo "${CLI} [command]"
echo "Commands: "
echo "  init                Init project and set configulation"
echo "  config              Set config porject"
echo "  deploy              Stack deploy (traefik and portainer) in swarm mode"
echo "  add                 Add new route in traefik with template(./template/sample.yaml)"
echo ""
echo "Optional tools:"
echo "  install-compose     Install docker-compose version ${COMPOSE_VERSION}"
echo "  cli-update          update '${CLI}' helper"
echo ""
