#!/bin/bash

# This script installs the tools needed to automatically generate the
# code for a new service, together with their dependencies.
# In particular, it installs the pyang-swagger tool that is used to
# generate the swagger-compatible REST APIs and the swagger-codegen
# tool that is used to generate the service stub.
#
# In addition, this script installs the polycube-codegen application that
# can be used to interact with the aforementioned tools and generate the
# service stub and/or the REST APIs given the YANG model of the new service.
#
# Run the polycube-codegen application form the terminal after executing this
# script in order to get the needed information.
#
# The script will download the tools if they are not installed, while it will
# update those tools otherwise.

function success_message {
  set +x
  echo
  echo 'Installation completed successfully'
}

_pwd=$(pwd)

set -e

[ -z ${SUDO+x} ] && SUDO='sudo'

echo "Installing polycube-codegen"

APT_CMD="apt"
CONFIG_PATH=$HOME/.config/polycube/
SWAGGER_CODEGEN_CONFIG_FILENAME=swagger_codegen_config.json

if hash apt 2>/dev/null; then
    APT_CMD="apt"
fi

$SUDO $APT_CMD update -y

# Install python dependencies
PACKAGES=""
PACKAGES+=" sudo git wget"
PACKAGES+=" python-minimal python-pip python-setuptools" # dependencies for pyang swagger
PACKAGES+=" default-jre default-jdk maven" # dependencies for swaggercodegen

$SUDO $APT_CMD install -y $PACKAGES

cd pyang-swagger/
./install.sh

GIT_SWAGGER_CODEGEN_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
GIT_SWAGGER_CODEGEN_COMMIT_HASH="$(git log -1 --format=%h)"

mkdir -p $CONFIG_PATH

cd ../swagger-codegen/
mvn -T $(getconf _NPROCESSORS_ONLN) -am -pl "modules/swagger-codegen-cli" package -DskipTests

$SUDO cp modules/swagger-codegen-cli/target/swagger-codegen-cli.jar /usr/local/bin/
cd ..
$SUDO cp polycube-codegen.sh /usr/local/bin/polycube-codegen

#Create configuration file for swagger-codegen
cat > ${CONFIG_PATH}${SWAGGER_CODEGEN_CONFIG_FILENAME} << EOF
{
  "gitUserId" : "polycube-network",
  "gitRepoId" : "${GIT_SWAGGER_CODEGEN_BRANCH}/${GIT_SWAGGER_CODEGEN_COMMIT_HASH}"
}
EOF

success_message

cd $_pwd
