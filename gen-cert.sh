#!/bin/bash

openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Local Security/OU=Local Security/CN=localhost" \
    -keyout certs/key.pem  -out certs/cert.pem


echo "Server's signed certificate"
openssl x509 -in certs/cert.pem -noout -text