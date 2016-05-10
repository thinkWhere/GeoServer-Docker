# docker-geoserver

A simple docker container that runs Geoserver influenced by this docker
recipe: https://github.com/kartoza/docker-geoserver by Tim Sutton

This container is configured to build with:
* Tomcat8.5
* Openjdk 8 
* GeoServer 2.8.3
* GeoServer Plugins: Any plugins downloaded to /resources/plugins


**Note:** We recommend using ``apt-cacher-ng`` to speed up package fetching -
you should configure the host for it in the provided 71-apt-cacher-ng file.

## Getting the image

The image can be downloaded from our image on dockerhub:


```shell
docker pull thinkwhere/geoserver
```

To build the image yourself do:

```shell
docker build -t thinkwhere/geoserver git://github.com/thinkwhere/geoserver-docker
```

To build with apt-cacher-ng (and minimised download requirements) you need to
clone this repo locally first and modify the contents of 71-apt-cacher-ng to
match your cacher host. Then build using a local url instead of directly from
github.

```shell
git clone git://github.com/thinkwhere/geoserver-docker
```
Now edit ``71-apt-cacher-ng`` 

## Options

### Geoserver Plugins

To build the GeoServer image with plugins (Control Flow, Monitor, Inspire, etc), 
download the plugin zip files from the GeoServer download page and put them in 
`resources/plugins` before building.  You should make sure these match the version of
GeoServer you are installing.
GeoServer version is controlled by the variable in Dockerfile, or download the WAR bundle
for the version you want to `resources/geoserver.zip` before building.

### Tomcat Extras

Tomcat is bundled with extras including docs, examples, etc.  If you don't need these, set
the `TOMCAT_EXTRAS` build-arg to `false` when building the image.  (This is the default in 
build.sh.)

```shell
docker build --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver-docker .
```

### Native JAI / JAI ImageIO

Native JAI and JAI ImageIO are included in the final image by default providing better
performance for raster data processing. Unfortunately they native JAI is not under active
development anymore. In the event that you face issues with raster data processing,
they can remove them from the final image by setting the `JAI_IMAGEIO` build-arg to `false`
when building the image.

```shell
docker build --build-arg JAI_IMAGEIO=false -t thinkwhere/geoserver-docker .
```

### GDAL Image Formats support

You can optionally include native GDAL libraries and GDAL extension in the image to enable
support for GDAL image formats.

To include native GDAL libraries in the image, set the `GDAL_NATIVE` build-arg to `true`
when building the image.

```shell
docker build --build-arg GDAL_NATIVE=true -t thinkwhere/geoserver-docker .
```

To include the GDAL extension in the final image download the extension and place the zip
file in the `resources/plugins` folder before building the image. If you use the build.sh
script to build the image simply uncomment the relevant part of the script.

```shell
#if [ ! -f resources/plugins/geoserver-gdal-plugin.zip ]
#then
#    wget -c http://netix.dl.sourceforge.net/project/geoserver/GeoServer/2.8.3/extensions/geoserver-2.8.3-gdal-plugin.zip -O resources/plugins/geoserver-gdal-plugin.zip
#fi
```

## Run

### External geoserver_data directory
You probably want to run Geoserver with an external geoserver_data directory mapped as a docker volume.
This allows the configuration to be persisted or shared with other instances. To create a running container 
with an external volume do:

```shell
mkdir -p ~/geoserver_data
docker run \
	--name=geoserver \
	-p 8080:8080 \
	-d \
	-v $HOME/geoserver_data:/opt/geoserver/data_dir \
	-t thinkwhere/geoserver
```

### Running multiple instances on the same machine
For installations with multiple containers on the same host, map port 8080 to a different port for each
instance.  It is recommended that the instance name contains the mapped port no for ease of reference.
Each instance should also have its own log file, specified by passing in the `GEOSERVER_LOG_LOCATION'
variable as illustrated in the example below.

```shell
mkdir -p ~/geoserver_data
docker run \
	--name=geoserver \
	-p 8085:8080 \
	-d \
	-v $HOME/geoserver_data:/opt/geoserver/data_dir \
	-e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" \
	-t thinkwhere/geoserver
```

### Setting Tomcat properties

To set Tomcat properties such as maximum heap memory size, create a `setenv.sh` 
file such as:

```shell
JAVA_OPTS="$JAVA_OPTS -Xmx1024M"
JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled"
```

Then pass the `setenv.sh` file as a volume at `/usr/local/tomcat/bin/setenv.sh` when running:

```shell
docker run -d \
    -v $HOME/tomcat/setenv.sh:/usr/local/tomcat/bin/setenv.sh \
    thinkwhere/geserver
```

This repository contains a ``run.sh`` script for your convenience.

**Note:** The default geoserver user is 'admin' and the password is 'geoserver'.
It is recommended that these are changed for production systems.

