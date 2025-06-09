# dart_mtls
Test server and client for mTLS

## creating certs

First generate keys:

```sh
openssl genrsa -out ca.key 2048
openssl genrsa -out server.key 2048
openssl genrsa -out client.key 2048
```

`client.ext`

```txt
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment
extendedKeyUsage = clientAuth
```

`client.noext.ext`

```txt
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment
```

`server.ext`

```txt
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = atsign.test
DNS.2 = localhost
DNS.3 = 127.0.0.1
```

Create CA cert, CSRs and certs

```sh
 openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt
 openssl req -new -key server.key -out server.csr
 openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile server.ext
 openssl req -new -key client.key -out client.csr
 openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -sha256 -extfile client.ext
 openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.noext.crt -days 365 -sha256 -extfile client.noext.ext
 ```
