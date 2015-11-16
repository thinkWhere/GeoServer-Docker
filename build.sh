#!/bin/sh

if [ ! -f resources/geoserver.zip ]
then
    wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/2.8.0/geoserver-2.8.0-bin.zip -O resources/geoserver.zip
fi
docker build -t kartoza/geoserver .
