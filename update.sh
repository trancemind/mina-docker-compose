#!/bin/bash
#
# Warning: this script has not been tested in MacOS.
# You probably would need to have GNU sed installed in order to use this script.
#

wdir=`dirname "$(realpath "$0")"`
conf_file="${wdir}/m.conf"
compose_file="${wdir}/docker-compose.yml"
delay="15"

MINA_TAG_MAIN="1.1.4-a8893ab"
MINA_TAG_ARCH="1.1.3-48401e9"
MINA_TAG_DEV="1.0.5-68200c7"

# Checking if the m.conf file exists
if ! [[ -f ${conf_file} ]]; then
 echo "Configuration file ${conf_file} not found in the current directory. Make sure you're running this script in the right place."
fi

# Checking if the docker-compose.yml exists
if ! [[ -f ${compose_file} ]]; then
 echo "Docker-compose file not found in the current directory. Make sure you're running this script in the right place."
fi

# Getting most recent config version from mina-docker-compose repo
cd ${wdir} && git pull -q

clear && echo "
WARNING!
  - This action will restart your existing mina daemon container!
  - If you not agree with this, press CTRL-C.
  - If you ready for upgrade, just wait ${delay} seconds.
"
sleep ${delay}

# Setting up recent TAGs for docker images
sed -i "s/^\(MINA_TAG_MAIN\s*=\s*\).*\$/\1${MINA_TAG_MAIN}/" "${conf_file}"
sed -i "s/^\(MINA_TAG_ARCH\s*=\s*\).*\$/\1${MINA_TAG_ARCH}/" "${conf_file}"
sed -i "s/^\(MINA_TAG_DEV\s*=\s*\).*\$/\1${MINA_TAG_DEV}/" "${conf_file}"

# Upgrading/restarting existing containers
docker-compose up -d

echo "
All done!
  - Your current mainnet container tag is: ${MINA_TAG_MAIN}
  - Your current mainnet-archive container tag is: ${MINA_TAG_ARCH}
"

docker-compose ps
