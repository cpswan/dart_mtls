# dart_mtls
Test server and client for mTLS

## creating certs

```sh
 openssl req -x509 -new -nodes -key ca.key -sha256 -days 365 -out ca.crt
 openssl req -new -key server.key -out server.csr
 openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -sha256 -extfile server.ext
 openssl req -new -key client.key -out client.csr
 openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365 -sha256 -extfile client.ext
 openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.noext.crt -days 365 -sha256 -extfile client.noext.ext
 ```
