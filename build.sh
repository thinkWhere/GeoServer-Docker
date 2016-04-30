#!/bin/sh

# Add in selected plugins.  Comment out or modify as required
if [ ! -f resources/geoserver-control-flow-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-control-flow-plugin.zip -O resources/geoserver-control-flow-plugin.zip
fi
if [ ! -f resources/geoserver-inspire-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-inspire-plugin.zip -O resources/geoserver-inspire-plugin.zip
fi
if [ ! -f resources/geoserver-monitor-plugin.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-monitor-plugin.zip -O resources/geoserver-monitor-plugin.zip
fi


docker build --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver .
