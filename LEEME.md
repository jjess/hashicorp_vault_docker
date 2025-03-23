## Referencias:

https://docs.pd-portfolio.net/en/guides/hashi-corp-vault-guide/
https://ahelpme.com/software/hashicorpvault/starting-hashicorp-vault-in-server-mode-under-docker-container/

## crear certificados

vault_cert.conf:

```
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = ES
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = Madrid
localityName                = Locality Name (eg, city)
localityName_default        = Madrid
organizationName            = Organization Name (eg, company)
organizationName_default    = My Company
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_default          = ubuntuserver3


[ req_ext ]
subjectAltName = @alt_names

[ v3_ca ]
subjectAltName = @alt_names
basicConstraints = critical,CA:TRUE
keyUsage = critical,digitalSignature,keyCertSign,cRLSign
extendedKeyUsage = serverAuth, clientAuth

[ alt_names ]
DNS.1   = ubuntuserver3
```

generate_cert.sh:

```
#!/bin/sh

mkdir -p vault
mkdir -p config/tls


openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout config/tls/vault.key -out config/tls/vault.crt -config vault_cert.conf

```


## docker-compose.yml:

```
version: '3.8'
services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_ADDR: "https://ubuntuserver3:8200"
    volumes:
      - ./vault:/vault
      - ./config:/etc/vault.d
    entrypoint: vault server -config=/etc/vault.d/vault.hcl

volumes:
  vault:
    driver: local

```


```
docker-compose up -d
```

Entrar al contenedor para inicializarlo.

Tener en cuenta que los comandos 'vault' dentro del contenedor
requiren -tls-skip-verify para que no den error con certificados
autofirmados. También se puede usar una variable de entorno 
VAULT_SKIP_VERIFY=1

`
docker exec -it vault /bin/sh 

export VAULT_ADDR='https://ubuntuserver3:8200'
export VAULT_SKIP_VERIFY='true'

vault operator init -tls-skip-verify
Unseal Key 1: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 2: yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
Unseal Key 3: zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
Unseal Key 4: wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww
Unseal Key 5: vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

Initial Root Token: kkkkkkkkkkkkkkkkkkkkkkkkkkkk
                                                

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.

```

En FreeBSD instalar el cliente de vault para probar:

```
pkg install vault
```

Para probar:

```
export VAULT_ADDR='https://ubuntuserver3:8200'
export VAULT_SKIP_VERIFY='true'

vault operator unseal xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
vault operator unseal yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
vault operator unseal zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz


vault login kkkkkkkkkkkkkkkkkkkkkkkkkkkk

Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                kkkkkkkkkkkkkkkkkkkkkkkkkkkk
token_accessor       rrrrrrrrrrrrrrrrrrrrrrrr
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
```

## Crear un secret engine para almacenar valores

Primero hacer login como root, tal y como se hizo antes.

```
vault secrets enable -path=secret/ kv 

Success! Enabled the kv secrets engine at: secret/

```
 
Meter algo de ejemplo:

```
vault kv put secret/hello foo=world excited=yes
```


Leer el contenido de secret/hello:

```
vault kv get secret/hello

===== Data =====
Key        Value
---        -----
excited    yes
foo        world

```





