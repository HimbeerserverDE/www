#!/bin/sh

gunicorn \
	-b '[::]:8001' \
	--chdir /usr/local/searxng/searxng-src/searx \
	--pythonpath /usr/local/searxng/searxng-src,/usr/local/searxng/searx-pyenv/lib/python3.12/site-packages \
	searx.webapp
