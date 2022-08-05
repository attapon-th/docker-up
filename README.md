# Traefik setup for docker.

## Configuration 
 * Docker
 * Docker Compose
 * Docker stack - `docker swarm init`


- [x] [Traefik Proxy](./traefik/) - สำหรับทำ reverse proxy เหมาะใช้กับ Docker


## How to Use `Traefik Proxy`:
```
git clone https://github.com/attapon-th/traefik-setup.git


cd traefik-setup


# create docker network
docker network create --attachable --driver=overlay proxy


# start docker by docker-compsoe
docker-compose -f traefik/docker-compose.yaml up -d

## https
# dashboard: https://localhost:8080/

## http
# ping: http://localhost:8080/ping
```


## Optional:

1. `Portainer`
```
docker stack deploy -c portainer/portainer-agent-statck.yaml portainer
# http://localhost:9000
```