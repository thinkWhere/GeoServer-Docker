docker run --name=geoserver_test -p 8080:8080 -d -v $HOME/geoserver_data:/opt/geoserver/data_dir -t thinkwhere/geoserver:latest

