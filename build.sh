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

# Add in selected plugins.  Comment out or modify as required
if [ ! -f resources/plugins/geoserver-control-flow-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-control-flow-plugin.zip -O resources/plugins/geoserver-control-flow-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-inspire-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-inspire-plugin.zip -O resources/plugins/geoserver-inspire-plugin.zip
fi
if [ ! -f resources/plugins/geoserver-monitor-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-monitor-plugin.zip -O resources/plugins/geoserver-monitor-plugin.zip
fi


docker build --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver .
