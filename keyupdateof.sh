#!/bin/bash

#
# this is for my environment. you have need to make minior adjustments for yours
#

date=$(date +"%Y%m%d")
HOME="/opt/openfire"
RHOME="$HOME/resources"
SHOME="/opt/openfire/resources/scripts"
SEC="/opt/openfire/resources/security"
SSL="$SEC/ssl"
DOMAIN="your.domain.com"
CERTS="/etc/letsencrypt/live/$DOMAIN"

cd $HOME
tar cvzf $RHOME.tar.gz $RHOME

service nginx stop

letsencrypt-auto certonly --standalone -d $DOMAIN

service nginx start

#cat $CERTS/cert.pem $CERTS/chain.pem > $SSL/$DOMAIN.chained.crt

cp -f $CERTS/cert.pem $SSL/$DOMAIN.crt
cp -f $CERTS/chain.pem $SSL/$DOMAIN.chain.crt
cp -f $CERTS/fullchain.pem $SSL/$DOMAIN.chained.crt
cp -f $CERTS/privkey.pem $SSL/$DOMAIN.key

/etc/init.d/openfire stop

cp -f $SEC/keystore $SEC/keystore.bak
rm -f $SEC/keystore

/opt/openfire/jre/bin/keytool -import -trustcacerts -storepass changeit -alias "Let's Encrypt Authority X3" -file $SSL/$DOMAIN.chain.crt -keystore $SEC/truststore >/dev/null

openssl pkcs12 -export -in $SSL/$DOMAIN.chained.crt -inkey $SSL/$DOMAIN.key -out $SSL/$DOMAIN.allwithkey.p12 -name "$DOMAIN" -CAfile $SSL/$DOMAIN.chain.crt -passout pass:"changeit"

chown daemon.daemon $SSL/$DOMAIN.allwithkey.p12

chmod 640 $SSL/$DOMAIN.allwithkey.p12

/opt/openfire/jre/bin/keytool -importkeystore -deststorepass changeit -srcstorepass changeit -destkeystore $SEC/keystore -srckeystore $SSL/$DOMAIN.allwithkey.p12 -srcstoretype PKCS12 -alias "$DOMAIN"

/opt/openfire/jre/bin/keytool -import -trustcacerts -storepass changeit -alias "Let's Encrypt Authority X3" -file $SSL/$DOMAIN.chain.crt -keystore $SEC/keystore

/etc/init.d/openfire start
