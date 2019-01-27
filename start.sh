#!/bin/sh

if [ -z "$SERVER_NAME" ] ; then
  echo "No domains set, please fill -e 'DOMAINS=example.com www.example.com'"
  exit 1
fi

if [ -z "$EMAIL" ] ; then
  echo "No email set, please fill -e 'EMAIL=your@email.tld'"
  exit 1
fi

if [[ -z $STAGING ]]; then
  echo "Using the staging environment"
  ADDITIONAL="--staging"
fi

EMAIL_ADDRESS=${EMAIL}
LE_DOMAINS=${SERVER_NAME}

exp_limit="${EXP_LIMIT:-30}"
check_freq="${CHECK_FREQ:-30}"

WEBROOT_PATH="/tmp/letsencrypt"

le_fixpermissions() {
    echo "[INFO] Fixing permissions"
        chown -R ${CHOWN:-root:root} /etc/letsencrypt
        find /etc/letsencrypt -type d -exec chmod 755 {} \;
        find /etc/letsencrypt -type f -exec chmod ${CHMOD:-644} {} \;
}

le_renew() {
    echo "waiting for server to be ready...."
    sleep 30
    certbot certonly --webroot --agree-tos --renew-by-default -n --text ${ADDITIONAL} -m ${EMAIL_ADDRESS} -w ${WEBROOT_PATH} -d ${SERVER_NAME}
    le_fixpermissions
}

while true; do
le_renew
sleep 43000
done
