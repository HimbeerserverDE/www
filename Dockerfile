FROM httpd:2.4

EXPOSE 80/tcp

RUN apt update && apt install -y pandoc
