#! /bin/sh

source /srv/www/lib.sh

for FILE in ${FILES}; do
	ln -sf "/srv/www/sys/${FILE}" "/${FILE}"
done

ln -sf /usr/share/webapps/cgit/cgit.css /srv/www/static/base/cgit.css
