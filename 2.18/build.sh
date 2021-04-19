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

GS_VERSION=2.18.0

# Add in selected plugins.  Comment out or modify as required
plugins=(control-flow inspire monitor css ysld web-resource sldservice imagemosaic-jdbc )

for p in "${plugins[@]}"
do 
	if [ ! -f resources/plugins/geoserver-${p}-plugin.zip ]
	then
		wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-${p}-plugin.zip -O resources/plugins/geoserver-${p}-plugin.zip
	fi
done

## build options include:
#    TOMCAT_EXTRAS  [true | false]
#    GDAL_NATIVE    [true | false]  - default false; build with GDAL support
#    GS_VERSION              - specifies which version of geoserver is to be built

docker build --build-arg GS_VERSION=${GS_VERSION} --build-arg TOMCAT_EXTRAS=false --build-arg GDAL_NATIVE=true -t thinkwhere/geoserver:${GS_VERSION} .
