#!/bin/bash

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

# Create plugins folder if does not exist
if [ ! -d ./resources ]
then
    mkdir ./resources
fi

if [ ! -d ./resources/plugins ]
then
    mkdir ./resources/plugins
fi

GS_VERSION=$(cfg_get gs_version)
TOMCAT_IMAGE=$(cfg_get tomcat_image)
GDAL_VERSION=$(cfg_get gdal_version)
GDAL_NATIVE=$(cfg_get gdal_native)
TOMCAT_EXTRAS=$(cfg_get tomcat_extras)
BUILD_PLATFORM=$(cfg_get build_platform)
PLUGINS_CSV=$(cfg_get plugins)
COMMUNITY_PLUGINS_CSV=$(cfg_get community_plugins)

BUILD_GS_VERSION=${GS_VERSION%.*}

IFS=',' read -r -a plugins <<< "$PLUGINS_CSV"
IFS=',' read -r -a community_plugins <<< "$COMMUNITY_PLUGINS_CSV"

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

## build options include:
#    TOMCAT_EXTRAS  [true | false]
#    GDAL_NATIVE    [true | false]  - default false; build with GDAL support
#    GS_VERSION              - specifies which version of geoserver is to be built

# Valid for AMD64 (i.e., t3a.medium)
docker build --platform ${BUILD_PLATFORM} --build-arg GS_VERSION=${GS_VERSION} --build-arg TOMCAT_IMAGE=${TOMCAT_IMAGE} --build-arg GDAL_VERSION=${GDAL_VERSION} --build-arg TOMCAT_EXTRAS=${TOMCAT_EXTRAS} --build-arg GDAL_NATIVE=${GDAL_NATIVE} -t thinkwhere/geoserver:${GS_VERSION} .
# Valid also for ARM64 (i.e., t4g.medium)
# docker buildx build --build-arg GS_VERSION=${GS_VERSION} --build-arg TOMCAT_EXTRAS=false --build-arg GDAL_NATIVE=false --platform linux/arm64/v8 -t thinkwhere/geoserver:${GS_VERSION} --push .