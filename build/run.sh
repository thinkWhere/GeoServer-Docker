HTTP_PORT=8080
HTTP_MAX_HEADER_SIZE=524288

docker run --name=geoserver_${HTTP_PORT} -p ${HTTP_PORT}:8080 -d -v $HOME/geoserver_data:/opt/geoserver/data_dir -e "HTTP_MAX_HEADER_SIZE=524288" -t stevetarter/geoserver:2.18.3 /bin/sh -c conf/update_tomcat_settings.sh
