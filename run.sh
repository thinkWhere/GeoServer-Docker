#!/bin/bash
docker kill geoserver
docker rm geoserver

DATA_DIR=~/geoserver_data
if [ ! -d $DATA_DIR ]
then
    mkdir -p $DATA_DIR
fi 


docker run \
	--name=geoserver \
	-p 4080:8080 \
	-d \
	-t kartoza/geoserver
