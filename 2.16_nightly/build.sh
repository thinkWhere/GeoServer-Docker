#!/bin/sh

# Create plugins folder if does not exist
if [ ! -d ./resources ]
then
    mkdir ./resources
fi

if [ ! -d ./resources/plugins ]
then
    mkdir ./resources/plugins
fi

GS_VERSION=2.16

# This is build script for nightly builds, so delete all downloaded plugins first
rm resources/plugins/*.zip

# Add in selected plugins.  Comment out or modify as required
if [ ! -f resources/plugins/geoserver-control-flow-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-control-flow-plugin.zip -O resources/plugins/geoserver-control-flow-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-inspire-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-inspire-plugin.zip -O resources/plugins/geoserver-inspire-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-monitor-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-monitor-plugin.zip -O resources/plugins/geoserver-monitor-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-css-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-css-plugin.zip -O resources/plugins/geoserver-css-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-ysld-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-ysld-plugin.zip -O resources/plugins/geoserver-ysld-plugin.zip
fi
#if [ ! -f resources/plugins/geoserver-gdal-plugin.zip ]
#then
#    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-gdal-plugin.zip -O resources/plugins/geoserver-gdal-plugin.zip
#fi
if [ ! -f resources/plugins/geoserver-sldservice-plugin.zip ]
then
    wget -c https://build.geoserver.org/geoserver/${GS_VERSION}.x/ext-latest/geoserver-${GS_VERSION}-SNAPSHOT-sldservice-plugin.zip -O resources/plugins/geoserver-sldservice-plugin.zip
fi

docker build --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver .
## Note: disabling GWC may conflict with plugins in 2.9+ that have this as a dependency
#docker build --build-arg DISABLE_GWC=true --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver .
