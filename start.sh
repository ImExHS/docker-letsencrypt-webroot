#!/bin/bash

if [ -z "$DOMAINS" ] ; then
  echo "No domains set, please fill -e DOMAINS='example.com www.example.com'"
  exit 1
fi

if [ -z "$EMAIL" ] ; then
  echo "No email set, please fill -e EMAIL='your@email.tld'"
  exit 1
fi

DARRAYS=(${DOMAINS})
EMAIL_ADDRESS=${EMAIL}
LE_DOMAINS=("${DARRAYS[*]/#/-d }")

exp_limit="${EXP_LIMIT:-30}"
check_freq="${CHECK_FREQ:-30}"

run_renew_hook() {
    all_links=($(env | grep -oP '^[0-9A-Z_-]+(?=_ENV_LE_RENEW_HOOK)'))
    compose_links=($(env | grep -oP '^[0-9A-Z]+_[0-9A-Z_-]+_[0-9]+(?=_ENV_LE_RENEW_HOOK)'))
    
    except_links=($(
        for link in ${compose_links[@]}; do
            compose_project=$(echo $link | cut -f1 -d"_")
            compose_name=$(echo $link | cut -f2- -d"_" | sed 's/_[^_]*$//g')
            compose_instance=$(echo $link | grep -o '[^_]*$')
            echo ${compose_name}_${compose_instance}
            echo ${compose_name}
        done
    ))
    
    containers=($(
        for link in ${all_links[@]}; do
            [[ " ${except_links[@]} " =~ " ${link} " ]] || echo $link
        done
    ))
    
    for container in ${containers[@]}; do
        command=$(eval echo \$${container}_ENV_LE_RENEW_HOOK)
        command=$(echo $command | sed "s/@CONTAINER_NAME@/${container,,}/g")
        echo "[INFO] Run: $command"
        eval $command
    done
}

le_check_renew() {
    cert_file="/etc/letsencrypt/live/$DARRAYS/fullchain.pem"
    
    if [ -f $cert_file ]; then
    
        exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
        datenow=$(date -d "now" +%s)
        days_exp=$[ ( $exp - $datenow ) / 86400 ]
        
        echo "Checking expiration date for $DARRAYS..."
        
        if [ "$days_exp" -gt "$exp_limit" ] ; then
        	echo "The certificate is up to date, no need for renewal ($days_exp days left)."
        else
        	echo "The certificate for $DARRAYS is about to expire soon. Starting webroot renewal script..."
                letsencrypt certonly --webroot --agree-tos --renew-by-default --email ${EMAIL_ADDRESS} -w ${WEBROOT_PATH} ${LE_DOMAINS}
                run_renew_hook
        	echo "Renewal process finished for domain $DARRAYS"
        fi
    else
    	echo "[INFO] certificate file not found for domain $DARRAYS. Starting webroot script..."
        letsencrypt certonly --webroot --agree-tos --email ${EMAIL_ADDRESS} -w ${WEBROOT_PATH} ${LE_DOMAINS}
        run_renew_hook
    fi

    sleep ${check_freq}d
    le_check_renew
}

le_check_renew
