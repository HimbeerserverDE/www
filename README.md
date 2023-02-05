# www

Himbeerserver v3, formerly known as
[www.himbeerserver.de](https://github.com/HimbeerserverDE/www.himbeerserver.de).

This is a simple static markdown website with a Lua preprocessor
allowing dynamic content for placeholders in the markdown source.

No JavaScript is used, but there is a global CSS stylesheet.

Unlike the previous v3 this build is designed to run in a container.
Packaging for distro package managers again is planned.

## HTTPS

This image requires a TLS certificate and private key to start.
The server expects the files at `ssl/server.crt`
and `ssl/server.key`, respectively.

### Certbot

The image supports certificate management using certbot.

To initially obtain and install a certificate,
run the following commands (as root):

```
certbot --standalone -d YOURDOMAIN.TLD,www.YOURDOMAIN.TLD certonly

mkdir -p /PATH/TO/REPO/ssl
ln -s /etc/letsencrypt/live/YOURDOMAIN.TLD/fullchain.pem /PATH/TO/REPO/ssl/server.crt
ln -s /etc/letsencrypt/live/YOURDOMAIN.TLD/privkey.pem /PATH/TO/REPO/ssl/server.key
```

**Before doing this, verify that port 80 (TCP) on the host server is reachable
under both YOURDOMAIN.TLD and www.YOURDOMAIN.TLD.**

#### Renewal

Renewing or otherwise modifying an existing certificate is possible via
the webroot feature:

```
mkdir -p /PATH/TO/REPO/.well-known
certbot --standalone -w /PATH/TO/REPO -d YOURDOMAIN.TLD,www.YOURDOMAIN.TLD certonly
```

**Before doing this, verify that the container is already running
and reachable on port 80 (TCP).**
