#!/bin/bash

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-./build/build-config.yml}"
GS_PORT="${GS_PORT:-8085}"
DATA_DIR="${DATA_DIR:-$(pwd)/build/resources/data_dir}"

if [ ! -f "$CONFIG_FILE" ]
then
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

cfg_get() {
    local key="$1"
    local value
    value=$(grep -E "^${key}:" "$CONFIG_FILE" | head -n 1 | sed -E "s/^${key}:[[:space:]]*//")
    value=${value//\"/}
    value=${value//\'/}
    echo "$value"
}

GS_VERSION=$(cfg_get gs_version)

mkdir -p "$DATA_DIR"

docker rm -f geoserver_${GS_PORT} >/dev/null 2>&1 || true

docker run \
	--name=geoserver_${GS_PORT} \
	-p ${GS_PORT}:8080 \
	-d \
	-v "$DATA_DIR:/opt/geoserver/data_dir" \
	-e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_${GS_PORT}.log" \
	-t thinkwhere/geoserver:${GS_VERSION}


# alt docker run command if s3-geotiff plugin is used
# to ensure environment variables are set
# docker run \
	# --name=geoserver-s3-geotiff \
	# --env-file=$HOME\env.list
	# -p 8080:8080 \
	# -d \
	# -v $HOME/geoserver_data:/opt/geoserver/data_dir \
	# -v $HOME/tomcat_settings/setenv.sh:/usr/local/tomcat/bin/setenv.sh \
	# -t thinkwhere/geoserver-s3-geotiff