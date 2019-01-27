FROM certbot/certbot

ADD start.sh /bin/start.sh

ENTRYPOINT  [ "/bin/start.sh" ]
