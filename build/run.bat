docker run --name=geoserver_8080 -p 8080:8080 -d -v %HOME%/geoserver_data:/opt/geoserver/data_dir -e "HTTP_MAX_HEADER_SIZE=524288" -t stevetarter/geoserver:2.18.3
