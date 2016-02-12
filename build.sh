#!/bin/sh

if [ ! -f resources/geoserver.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.2/geoserver-2.8.2-bin.zip -O resources/geoserver.zip
fi
if [ ! -f resources/geoserver-plugin-css.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.2/extensions/geoserver-2.8.2-css-plugin.zip -O resources/geoserver-plugin-css.zip
fi
if [ ! -f resources/geoserver-plugin-printing.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.2/extensions/geoserver-2.8.2-printing-plugin.zip -O resources/geoserver-plugin-printing.zip
fi


docker build -t thinkwhere/geoserver .
