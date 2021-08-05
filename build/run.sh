GS_PORT=8080

docker run --name=geoserver_${GS_PORT} -p ${GS_PORT}:8080 -d -v $HOME/geoserver_data:/opt/geoserver/data_dir -t thinkwhere/geoserver:2.18.3
