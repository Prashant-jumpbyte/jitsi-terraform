#!/bin/bash

yum -y install http://mirror.grid.uchicago.edu/pub/linux/epel/epel-release-latest-7.noarch.rpm

yum -y install docker docker-compose git

systemctl enable docker
systemctl start docker

git clone https://github.com/jitsi/docker-jitsi-meet && cd docker-jitsi-meet

cp env.example .env

./gen-passwords.sh

sed -i 's/^HTTP_PORT.*$/HTTP_PORT=80/' .env
sed -i 's/^HTTPS_PORT.*$/HTTPS_PORT=443/' .env
sed -i 's/^TZ.*$/TZ=America\/Detroit/' .env
sed -i 's/^#PUBLIC_URL/PUBLIC_URL=https:\/\/meet.djmorris.net/' .env
sed -i 's/^#DOCKER_HOST.*$/DOCKER_HOST_ADDRESS=10.1.1.7/' .env
sed -i 's/^#ENABLE_LET/ENABLE_LET/' .env
sed -i 's/^#LETS.*_DOMAIN.*$/LETSENCRYPT_DOMAIN=meet.djmorris.net/' .env
sed -i 's/^#LETS.*EMAIL.*$/LETSENCRYPT_EMAIL=doug@dougjm.morris.com/' .env

mkdir -p ~/.jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody,jicofo,jvb,jigasi,jibri}
