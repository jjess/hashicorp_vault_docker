#!/bin/sh

mkdir -p vault
mkdir -p config/tls


openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout config/tls/vault.key -out config/tls/vault.crt -config vault_cert.conf
