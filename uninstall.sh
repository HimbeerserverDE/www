#! /bin/sh

source /srv/www/lib.sh

for FILE in ${FILES}; do
	rm "/${FILE}"
done

for DIR in ${DIRS}; do
	rm -r "${DIR}"
done
