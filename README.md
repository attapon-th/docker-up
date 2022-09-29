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
    mkdir -p ~/treafik
    cd ~/treafik
    ```

2. Download cli helper

    ```shell
    curl -SL https://raw.githubusercontent.com/attapon-th/traefik-setup/main/cli.sh -o ./cli \
    && chmod +x ./cli

    ./cli
    ```

    output:

    ```raw
   ./cli [command]
   Commands: 
        init                Init project and set configulation
        config              Set config porject
        deploy              Stack deploy (traefik and portainer) in swarm mode
        install-compose     Install docker-compose version v2.11.2
        add                 Add new route in traefik with template(./template/sample.yaml)
    ```

3. Start Init and deploy project

    ```shell
    ./cli init
    ./cli deploy
    ```


## Add basic reverse proxy

```shell
./cli add
```

## Optional: Install `docker compose`

```shell
./cli install-compose

docker compose version
```
