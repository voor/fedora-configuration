#!/bin/bash -exu

rm .secrets/unifi.keystore.jks || :

# Concat together both private keys.
cat .secrets/privkey.pem .secrets/cert.pem > .secrets/server.pem
# # Send it over to the server.
# scp .secrets/server.pem voor@router.planetvoor.com:~
# ssh voor@router.planetvoor.com 'sudo su -c "mv /home/voor/server.pem /etc/lighttpd/server.pem"'
# ssh voor@router.planetvoor.com 'sudo su -c "chown root:root /etc/lighttpd/server.pem"'

openssl pkcs12 -export -in .secrets/fullchain.pem -inkey .secrets/privkey.pem -certfile .secrets/cert.pem -out .secrets/unifi.p12 -name unifi -password pass:aircontrolenterprise

keytool -importkeystore -srckeystore .secrets/unifi.p12 -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -destkeystore .secrets/unifi.keystore.jks -storepass aircontrolenterprise

cp .secrets/cert.pem .secrets/cloudkey.crt && \
  cp .secrets/privkey.pem .secrets/cloudkey.key

pushd .secrets && \
  tar cf cert.tar cloudkey.crt cloudkey.key unifi.keystore.jks && \
  popd

scp .secrets/cert.tar root@unifi.planetvoor.com:/etc/ssl/private

# Verify:
# keytool -list -v -keystore .secrets/unifi.keystore.jks
#

# Do this on the router:
# kill -SIGINT $(cat /var/run/lighttpd.pid)
# ssh voor@router.planetvoor.com 'sudo su -c "kill -SIGINT $(cat /var/run/lighttpd.pid)"'
# /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
# ssh voor@router.planetvoor.com 'sudo su -c "/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf"'

# Do this on the cloud key:
ssh root@unifi.planetvoor.com 'tar xf /etc/ssl/private/cert.tar -C /etc/ssl/private/ \
  && chown root:ssl-cert /etc/ssl/private/cloudkey.crt /etc/ssl/private/cloudkey.key /etc/ssl/private/unifi.keystore.jks /etc/ssl/private/cert.tar \
  && chmod 640 /etc/ssl/private/cloudkey.crt /etc/ssl/private/cloudkey.key /etc/ssl/private/unifi.keystore.jks /etc/ssl/private/cert.tar \
  && nginx -t && /etc/init.d/nginx restart && /etc/init.d/unifi restart'
