#!/bin/bash

_pwd=$(pwd)

set -e

SWAGGER_CONFIG_FILE=$HOME/.config/polycube/swagger_codegen_config.json
POLYCUBE_CODEGEN_LOG=/dev/null
SWAGGER_CODEGEN_CLI=/usr/local/bin/swagger-codegen-cli.jar
CLIENT_LANG=polycube
ONLINE_GENERATOR_URL=https://generator.swagger.io/api/gen/clients

function exit_error() {
	if [ "$?" -ne "0" ]; then
		echo "Failed to create the C++ stub"
		cat $POLYCUBE_CODEGEN_LOG
	fi
	exit 0
}

function show_help() {
usage="$(basename "$0") [-h] [-i input_yang] [-o output_folder] [-s output_swagger_file] [-l client_language]
Polycube code generator that translates a YANG file into an polycube C++ service stub

where:
    -h  show this help text
    -i  path to the input YANG file
    -o  path to the destination folder where the service stub will be placed
    -s  path to the destination swagger file (optional)
    -l  language used to generate service's client library (optional)"

echo "$usage"
}


trap exit_error EXIT

while getopts :i:o:s:l:h option; do
 case "${option}" in
 h|\?)
	show_help
	exit 0
	;;
 i) YANG_PATH=${OPTARG}
	;;
 o) OUT_FOLDER=${OPTARG}
	;;
 s) OUT_SWAGGER_PATH=${OPTARG}
 	;;
 l) CLIENT_LANG=${OPTARG}
 	;;	
 :)
    echo "Option -$OPTARG requires an argument." >&2
    show_help
    exit 0
    ;;
 esac
done

json_body=$OUT_FOLDER/jsonbodytmp

if [ -f $POLYCUBE_CODEGEN_LOG ]; then
	rm $POLYCUBE_CODEGEN_LOG
fi

if [ -z ${YANG_PATH+x} ]; then
	echo "You should specify the YANG file with the -i option" >&2;
	show_help
	exit 0
fi

if [ ! -f "$YANG_PATH" ]; then
	echo "$YANG_PATH does not exist" >&2;
	exit 0
fi

if [ -z ${OUT_FOLDER+x} ] && [ -z ${OUT_SWAGGER_PATH+x} ]; then
	echo "You should specify the output folder file with the -o option" >&2;
	show_help
	exit 0
fi

if [[ "$POLYCUBE_IN_DOCKER" = "true" ]]; then
	POLYCUBE_BASE_DATAMODELS_FOLDER="/polycube-base-datamodels"
fi

if [ -z ${POLYCUBE_BASE_DATAMODELS_FOLDER+x} ]; then
	POLYCUBE_BASE_DATAMODELS_FOLDER='/usr/local/include/polycube/datamodel-common/'
fi

now="$(date '+%Y_%m_%d_%H_%M_%S')"
json_filename="$now"_api.json
#echo "$now"

pyang -f swagger -p $POLYCUBE_BASE_DATAMODELS_FOLDER $YANG_PATH -o /tmp/"$json_filename" > $POLYCUBE_CODEGEN_LOG 2>&1

if [ -n "${OUT_SWAGGER_PATH+set}" ]; then
	cp /tmp/"$json_filename" $OUT_SWAGGER_PATH
	echo "Swagger file saved in $OUT_SWAGGER_PATH"
	exit 0
fi

if [ "$CLIENT_LANG" == "polycube" ]; then
	if [ -f $SWAGGER_CONFIG_FILE ]; then
		java -jar $SWAGGER_CODEGEN_CLI generate -l polycube -i /tmp/"$json_filename" \
			-o $OUT_FOLDER --config $SWAGGER_CONFIG_FILE > $POLYCUBE_CODEGEN_LOG 2>&1
	else
		java -jar $SWAGGER_CODEGEN_CLI generate -l polycube -i /tmp/"$json_filename" \
			-o $OUT_FOLDER > $POLYCUBE_CODEGEN_LOG 2>&1
	fi
else
	# Let's use the online generator to generate the service clients
	if [ ! -d "$OUT_FOLDER" ]; then mkdir $OUT_FOLDER; fi
	swagger_file=$(</tmp/"$json_filename")
	echo ' { "spec": '${swagger_file}' }' >> $json_body
	res=$(curl -H "Content-type: application/json" -X POST -d @"$json_body" ${ONLINE_GENERATOR_URL}/${CLIENT_LANG})
	download_url=$(jq -r '.link' <<< "$res")
	if [ $? -ne 0 ] || [ -z "$download_url" ] || [ "$download_url" == "null" ]; then
		echo "Unable to generate the clients stub for ${CLIENT_LANG}"
		exit 1
	fi

	wget -O "$OUT_FOLDER/${CLIENT_LANG}_client_api.zip" $download_url
fi

rm /tmp/"$json_filename"
rm $json_body > /dev/null 2>&1 || true
cd $_pwd

echo "$CLIENT_LANG output generated under $OUT_FOLDER"
exit 0


