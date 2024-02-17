#! /bin/sh

source /srv/www/lib.sh

for FILE in ${FILES}; do
	rm "/${FILE}"
done
