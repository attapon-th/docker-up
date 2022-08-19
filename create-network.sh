#!/usr/bin/sh

echo "Create Docker Network name: 'proxy'"
docker network create --attachable --driver=overlay proxy || echo "docker network with name 'proxy' already exists"
echo "Press any key to continue . . ."
read 