# authenticator.sh
script to make DNS authentication with letsencrypt/cerbot certificate.
change API_KEY and API_SECRET in global variables sections and save the file in /usr/local/bin/authenticator.sh
add execution permissions to the script

```
chmod +x /usr/local/bin/authenticator.sh
```

certbot command to use with this script

```
certbot certonly --manual --preferred-challenges=dns --manual-auth-hook /usr/local/bin/authenticator.sh -d '*.example.com'
```

# upload certificate to kubernetes namespaces

```
DOMAIN=example.com
for NAMESPACE in monitoring chef kubernetes-dashboard; do kubectl -n ${NAMESPACE} delete secret wildcard.${DOMAIN}.crt; kubectl -n ${NAMESPACE} create secret tls wildcard.${DOMAIN}.crt --key wildcard.${DOMAIN}.pem --cert wildcard.${DOMAIN}.crt; done
```

# upload to CDN77

# upload to dockerswarm haproxy

```
DOMAIN=example.com
docker secret create haproxy-star.${DOMAIN}-$(date +%Y-%m) haproxy-star.${DOMAIN}-$(date +%Y-%m)
vi docker-compose.yml
docker stack deploy -c docker-compose.yml stack_haproxy
```
