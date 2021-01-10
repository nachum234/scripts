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
