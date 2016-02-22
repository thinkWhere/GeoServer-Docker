# docker-geoserver

A simple docker container that runs Geoserver influenced by this docker
recipe: https://github.com/eliotjordan/docker-geoserver/blob/master/Dockerfile
and is a modified version of the container kartoza/geoserver by Tim Sutton (tim@kartoza.com)

This container is built with:
* Tomcat8
* GeoServer 2.8.2
* GeoServer Plugins:  Printing; CSS;

**Note:** We recommend using ``apt-cacher-ng`` to speed up package fetching -
you should configure the host for it in the provided 71-apt-cacher-ng file.

## Getting the image

The image can be downloaded from our image on dockerhub:


```
docker pull thinkwhere/geoserver
```

To build the image yourself do:

```
docker build -t thinkwhere/geoserver git://github.com/thinkwhere/geoserver-docker
```

To build with apt-cacher-ng (and minimised download requirements) you need to
clone this repo locally first and modify the contents of 71-apt-cacher-ng to
match your cacher host. Then build using a local url instead of directly from
github.

```
git clone git://github.com/thinkwhere/geoserver-docker
```
Now edit ``71-apt-cacher-ng`` 


## Run

It is recommended that Geoserver is run with an external geoserver_data directory mapped as a docker volume
allowing the configuration to be persisted or shared with other instances. To create a running container 
with an external volume do:

```
mkdir -p ~/geoserver_data
docker run \
	--name=geoserver_8085 \
	-p 8085:8080 \
	-d \
	-v $HOME/geoserver_data:/opt/geoserver/data_dir \
	-e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" \
	-t thinkwhere/geoserver
```

For installations with multiple containers on the same machine, map port 8080 to a different port for each
instance.  It is recommended that the instance name contains the mapped port no for ease of reference.

This repository contains a ``run.sh`` script for your convenience.

**Note:** The default geoserver user is 'admin' and the password is 'geoserver'.
It is recommended that these are changed for production systems.

