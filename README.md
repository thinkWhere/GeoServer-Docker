# docker-geoserver

A simple docker container that runs Geoserver influenced by this docker
recipe: https://github.com/kartoza/docker-geoserver by Tim Sutton. Created with input from GeoSolutions.

This container is configured to build with:
* Tomcat9
* Openjdk 11 
* GeoServer 2.8.x +
* GeoServer Plugins: Any plugins downloaded to /resources/plugins  folder will be included in the container
* Truetype fonts: Any .ttf fonts copied to the /resources/fonts folder will be included in the container


**Note:** We recommend using ``apt-cacher-ng`` to speed up package fetching -
you should configure the host for it in the provided 71-apt-cacher-ng file.

## Getting Started

The image can be downloaded from our image on dockerhub.  There are tagged images for most versions that have been released since 2.8:

```shell
docker pull stevetarter/geoserver
```

To build the image yourself:

```shell
docker build -t stevetarter/geoserver git://github.com/SteveTarter/geoserver-docker/build
```

Or for more control over the contents of the image, clone the repository first.  This way you can specify the version to build, and choose which fonts and plugins to include 


```shell
git clone git://github.com/SteveTarter/geoserver-docker

cd geoserver/build

docker build --build-arg GS_VERSION=2.18.2 -t mygeoserver .
```

### Build scripts

For convenience, there is a `build.bat` and `build.sh` for running the build.
- Edit these with the GeoServer version you want to build
- Edit these to set the plugins variable with the list of plugins to include in the build
- Run the appropriate build.x file for your environment  (build.bat for Docker in Windows;  build.sh for Docker in Linux)


## Options

### Geoserver Plugins

To build the GeoServer image with plugins (Control Flow, Monitor, Inspire, etc), 
download the plugin zip files from the GeoServer download page and put them in 
`resources/plugins` before building.  You should make sure these match the version of
GeoServer you are installing.
GeoServer version is controlled by the variable in Dockerfile or the build script, or download the WAR bundle
for the version you want to `resources/geoserver.zip` before building.

### Community Plugins

Community plugins are also available (S3 Geotiff) and can be added by placing the appropraite zip file(s) in the same location.
They are not available from the SourceForge source used in the build scripts, so additional scripting has been 
included to source them from [GeoSever](https://build.geoserver.org/).  Make sure that these lines are included and the list of 
plugins includes the plugin(s) required.
### Custom Fonts

To include any .ttf fonts with symbols in your container, copy them into the `resources/fonts` folder
before building.

This repo bundles the following 3rd-party fonts:

    * UN OCHA fonts for humanitarian relief mapping (http://reliefweb.int/report/world/world-humanitarian-and-country-icons-2012).
    * Roboto fonts from google (https://github.com/google/roboto/). 
    * Liberation Sans fonts from Red Hat (https://www.dafont.com/liberation-sans.font). 


### Tomcat Extras

Tomcat is bundled with extras including docs, examples, etc.  If you don't need these, set
the `TOMCAT_EXTRAS` build-arg to `false` when building the image.  (This is the default in 
build.sh.)

```shell
docker build --build-arg TOMCAT_EXTRAS=false -t stevetarter/geoserver-docker .
```

### GeoWebCache

GeoServer is installed by default with the integrated GeoWebCache functionality.  If you are using
the stand-alone GeoWebCache, or another caching engine such as MapProxy, you can remove the built-in GWC
by setting the `DISABLE_GWC` build-arg to `true` when building the image.

```shell
docker build --build-arg DISABLE_GWC=true -t stevetarter/geoserver-docker .
```

**Note:** this removes all *gwc* jar files from the installation. If you are building with plugins that have 
dependencies on the gwc classes, using this option could prevent geoserver from initializing.  
(examples include:  INSPIRE plugin v2.9.2+; control-flow plugin v2.9.2+)

### Native JAI / JAI ImageIO

Native JAI and JAI ImageIO are included in the final image by default providing better
performance for raster data processing. Unfortunately they native JAI is not under active
development anymore. In the event that you face issues with raster data processing,
they can remove them from the final image by setting the `JAI_IMAGEIO` build-arg to `false`
when building the image.

```shell
docker build --build-arg JAI_IMAGEIO=false -t stevetarter/geoserver-docker .
```

### GDAL Image Formats support

You can optionally include native GDAL libraries and GDAL extension in the image to enable
support for GDAL image formats.

To include native GDAL libraries in the image, set the `GDAL_NATIVE` build-arg to `true`
when building the image.

```shell
docker build --build-arg GDAL_NATIVE=true -t stevetarter/geoserver-docker .
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

### S3 Geotiff plugin

The S3 Geotiff plugin is required to serve GeoTiffs from S3.<br>
NOTE: that it is a community plugin and therefore not officially supported

This plugin requires that environment variables are set for:
- AWS_ACCESS_KEY
- AWS_SECRET_KEY

These are included in the setenv.sh file in tomcat_settings and should be edited to have appropriate values.

See [Setting Tomcat properties](#setting-tomcat-properties) for an example of including this.

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
	-t stevetarter/geoserver
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
	-t stevetarter/geoserver
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
    stevetarter/geserver
```

It is also possible to pass in custom values to Tomcat which are controlled in server.xml, for example `MaxHttpHeaderSize`. A full list of these parameters can be found in `build/tomcat/update_tomcat_settings.sh`

Environemnt variables can be passed in to the `docker run` command, as well as a request to run `update_tomcat_settings.sh` which will pass these values into the Tomcat `server.xml`. 

For example - 

```shell
docker run -e "HTTP_MAX_HEADER_SIZE=524288" -t stevetarter/geoserver:2.18.3 /bin/sh -c conf/update_tomcat_settings.sh
```


This repository contains a ``run.sh`` script for your convenience.

### Using docker-compose

Docker-compose allows you to deploy a load-balanced cluster of geoserver containers with a single command.  A sample docker-compose.yml configuration file is included in this repository, along with a sample nginx configuration file.

To deploy using docker-compose:

1. copy nginx folder from this repository to your machine.
2. copy tomcat_settings folder from this repository to your machine.
3. copy docker-compose.yml to your machine.  Edit the volume entries to reflect the correct location of your geoserver_data, nginx and tomcat_settings folders on your machine.
4. type `docker-compose up -d`  to start up a load-balanced cluster of 2x geoserver containers + nginx.
5. access geoserver services at  http://localhost/geoserver/wms?

**Note:** The default geoserver user is 'admin' and the password is 'geoserver'.
It is recommended that these are changed for production systems.

