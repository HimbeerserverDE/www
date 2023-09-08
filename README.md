# www

Himbeerserver v3, formerly known as
[www.himbeerserver.de](https://github.com/HimbeerserverDE/www.himbeerserver.de).

This is a simple static markdown website with a Lua preprocessor
allowing dynamic content for placeholders in the markdown source.

No JavaScript is used, but there is a global CSS stylesheet.

Unlike the previous v3 this build is designed to run in a container.
Packaging for distro package managers again is not planned.

## HTTPS

This image does not support HTTPS and is not exposed to the internet.
You should use [httpmux](https://github.com/HimbeerserverDE/httpmux)
to handle this.
