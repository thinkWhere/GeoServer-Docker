#!/bin/bash

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-./build-config.yml}"

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

# GS_VERSION can be passed as first arg; fallback to config value.
GS_VERSION="${1:-$(cfg_get gs_version)}"
BUILD_GS_VERSION=${GS_VERSION%.*}
PLUGINS_CSV=$(cfg_get plugins)
COMMUNITY_PLUGINS_CSV=$(cfg_get community_plugins)

IFS=',' read -r -a plugins <<< "$PLUGINS_CSV"
IFS=',' read -r -a community_plugins <<< "$COMMUNITY_PLUGINS_CSV"

echo "Build ${GS_VERSION}"
echo "Build minor ${BUILD_GS_VERSION}"

# Create plugins folder if does not exist
if [ ! -d ./resources ]
then
    mkdir ./resources
fi

if [ ! -d ./resources/plugins ]
then
    mkdir ./resources/plugins
fi

for p in "${plugins[@]}"
do
	p=$(echo "$p" | xargs)
	[ -z "$p" ] && continue
	if [ ! -s resources/plugins/geoserver-${p}-plugin.zip ]
	then
		wget https://sourceforge.net/projects/geoserver/files/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-${p}-plugin.zip/download -O resources/plugins/geoserver-${p}-plugin.zip
		echo "geoserver-${p}-plugin downloaded."
	else
		echo "Skipping existing plugin: geoserver-${p}-plugin.zip"
	fi
done

# Community plugins are not available from sourgeforge
# therefore source from https://build.geoserver.org/
for c in "${community_plugins[@]}"
do
	c=$(echo "$c" | xargs)
	[ -z "$c" ] && continue
	if [ ! -s resources/plugins/geoserver-${c}-plugin.zip ]
	then
		wget https://build.geoserver.org/geoserver/${BUILD_GS_VERSION}.x/community-latest/geoserver-${BUILD_GS_VERSION}-SNAPSHOT-${c}-plugin.zip -O resources/plugins/geoserver-${c}-plugin.zip
		echo "geoserver-${c}-plugin downloaded."
	else
		echo "Skipping existing community plugin: geoserver-${c}-plugin.zip"
	fi
done
