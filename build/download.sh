#!/bin/bash

# GS_VERSION param and abbreviated version
GS_VERSION=2.23.0 #$1
echo "Build $GS_VERSION"
BUILD_GS_VERSION=${GS_VERSION:0:-2}
echo "Build Minor $BUILD_GS_VERSION"

# Create plugins folder if does not exist
if [ ! -d ./resources ]
then
    mkdir ./resources
fi

if [ ! -d ./resources/plugins ]
then
    mkdir ./resources/plugins
fi

# Add in selected plugins.  Comment out or modify as required
plugins=(control-flow inspire monitor css ysld web-resource sldservice imagemosaic-jdbc gwc-s3)

for p in "${plugins[@]}"
do
	if [ ! -f resources/plugins/geoserver-${p}-plugin.zip ]
	then
	# https://sourceforge.net/projects/geoserver/files/GeoServer/2.23.0/extensions/geoserver-2.23.0-gdal-plugin.zip
		wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-${p}-plugin.zip -O resources/plugins/geoserver-${p}-plugin.zip
	fi
done

# Community plugins are not available from sourgeforge
# therefore source from https://build.geoserver.org/
community_plugins=(s3-geotiff )
for c in "${community_plugins[@]}"
do
	if [ ! -f resources/plugins/geoserver-${p}-plugin.zip ]
	then
	# https://build.geoserver.org/geoserver/2.23.x/community-latest/geoserver-2.23-SNAPSHOT-jms-cluster-plugin.zip
		wget -c https://build.geoserver.org/geoserver/${BUILD_GS_VERSION}.x/community-latest/geoserver-${BUILD_GS_VERSION}-SNAPSHOT-${c}-plugin.zip -O resources/plugins/geoserver-${p}-plugin.zip
	fi
done
