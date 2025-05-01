#! /bin/sh

. /srv/www/lib.sh

for DIR in ${DIRS}; do
	mkdir -p "${DIR}"
done

for FILE in ${FILES}; do
	ln -sf "/srv/www/sys/${FILE}" "/${FILE}"
done
