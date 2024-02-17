#! /bin/sh

source /srv/www/lib.sh

FILES=`get_files`
for FILE in ${FILES}; do
	ln -sf "/srv/www/sys/${FILE}" "/${FILE}"
done
