FROM httpd:2.4

EXPOSE 80/tcp

RUN apt update && apt install -y lua5.4 pandoc

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
COPY ./cgi-bin/ /usr/local/apache2/cgi-bin
COPY ./common/ /usr/local/share/lua/5.4
COPY ./htdocs/ /usr/local/apache2/htdocs
