#!/bin/bash
docker kill geoserver_8085
docker rm geoserver_8085

DATA_DIR=~/geoserver_data
if [ ! -d $DATA_DIR ]
then
    mkdir -p $DATA_DIR
fi 


docker run \
	--name=geoserver_8085 \
	-p 8085:8080 \
	-d \
	-v $DATA_DIR:/opt/geoserver/data_dir \
	-e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" \
	-t thinkwhere/geoserver
