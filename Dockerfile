FROM certbot/certbot

RUN mkdir /etc/letsencrypt/certs
COPY start.sh /bin/start.sh

ENTRYPOINT  [ "/bin/start.sh" ]
