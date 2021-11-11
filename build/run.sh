docker run --name=geoserver_8080 -p 8080:8080 -d -v $HOME/geoserver_data:/opt/geoserver/data_dir -t stevetarter/geoserver:2.18.3
