# www

Himbeerserver v3, formerly known as
[www.himbeerserver.de](https://github.com/HimbeerserverDE/www.himbeerserver.de).

This is a simple static markdown website and cgit instance powered by caddy.

No JavaScript is used, but there is a global CSS stylesheet.

The `sys` directory contains the filesystem structure to copy to the rootfs.
This repository should be cloned to `/srv/www`.
The `install.sh` script contains symlinks for configuration files to `/srv/www`,
overwriting existing files.
The `uninstall.sh` script removes them again without restoring the original files.

## Required system packages

Alpine:

```
apk add caddy-openrc cgit python3 py3-markdown py3-pygments
```

## Required caddy plugins

cgit requires regular CGI (not fastcgi):

```
caddy add-package github.com/aksdb/caddy-cgi/v2
```

## HTTPS

This configuration handles HTTPS setup automatically.
