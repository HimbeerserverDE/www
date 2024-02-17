#! /bin/sh

source /srv/www/lib.sh

FILES=`get_files`
for FILE in ${FILES}; do
	rm "/${FILE}"
done
