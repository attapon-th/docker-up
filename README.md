# Traefik setup for docker swarm mode

Can use:

- docker stack deploy
- docker compose
- docker run


## Requirement

- Docker - [Installation](https://docs.docker.com/engine/install/)

- Docker Compose - [Release Page](https://github.com/docker/compose/releases)

## How to

1. Create directory project

  ```shell
  mkdir -p ~/traefik
  cd ~/traefik
  ```

2. Download cli helper
  ```shell
  curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/cli.sh -o ./cli \
  && chmod +x ./cli
  ```

  test use:
  ```raw
  ./cli
  Commands: 
      init                Init project and set configulation
      config              Set config porject
      deploy              Stack deploy (traefik and portainer) in swarm mode
      add                 Add new route in traefik with template(./template/sample.yaml)
  ```

3. Start Docker Swarm Mode

  ```shell
  docker swarm init
  ```

4. Init traefik `init` and `deploy` traefik

  ```shell
  ./cli init
  ./cli deploy
  ```

## Default URL
 - `https://__DOMAIN__/portainer`
 - `https://__DOMAIN__:8080/dashboard`
 - `https://__DOMAIN__:8080/ping`
 - `https://__DOMAIN__/ping`


## Use Traefik in another Docker stack

```yaml
# ----- ENV required -------
# SERVICE_NAME=
# SERVICE_PORT=
# DOMAIN=
# PREFIX=
# --------------------------
version: "3.8"
services:
  ${SERVICE_NAME}:
    imange: ...
    deploy:
      mode: replicated
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.${SERVICE_NAME}.tls=true"
        - "traefik.http.routers.${SERVICE_NAME}.rule=Host(`${DOMAIN:-localhost}`) && PathPrefix(`${PREFIX:-/}`)"
        - "traefik.http.routers.${SERVICE_NAME}.entryPoints=web,websecure"
        - "traefik.http.services.${SERVICE_NAME}.loadbalancer.server.port=${SERVICE_PORT:-80}"
    networks:
      - proxy

networks:
  proxy:
    external: true
```

## ADD service filebrowser for edit config traefik
```yaml
# ENV required
# --------------------------------------------
# SERVICE_NAME=filebrowser4traefik
# DOMAIN=localhost
# BASE_URL=/filebrowser4traefik
# VOLUME_MOUNT=/etc/traefik
# PUID=1000
# PGID=1000
# --------------------------------------------
# END ENV
version: "3.8"
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    environment:
      TZ: Asia/Bangkok
      PUID: ${PUID}
      PGID: ${PGID}
    # default user: admin:admin
    command: --baseurl "${BASE_URL}"
    deploy:
      mode: replicated
      replicas: 1
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.${SERVICE_NAME}.tls=true"
        - "traefik.http.routers.${SERVICE_NAME}.entrypoints=web,websecure"
        - "traefik.http.routers.${SERVICE_NAME}.rule=Host(`${DOMAIN}`) && PathPrefix(`${BASE_URL}`)"
        - "traefik.http.services.${SERVICE_NAME}.loadbalancer.server.port=80"
    networks:
      - proxy
    volumes:
      - ${VOLUME_MOUNT}:/srv

networks:
  proxy:
    external: true
```