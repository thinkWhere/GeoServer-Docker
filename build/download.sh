#!/bin/bash

# GS_VERSION param and abbreviated version
GS_VERSION=$1
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
plugins=(control-flow inspire monitor css ysld web-resource sldservice imagemosaic-jdbc )

for p in "${plugins[@]}"
do
	if [ ! -f resources/plugins/geoserver-${p}-plugin.zip ]
	then
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
		wget -c https://build.geoserver.org/geoserver/${BUILD_GS_VERSION}.x/community-latest/geoserver-${BUILD_GS_VERSION}-SNAPSHOT-${c}-plugin.zip -O resources/plugins/geoserver-${p}-plugin.zip
	fi
done
