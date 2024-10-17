#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
# Defaults to amd64:
FROM tomcat:9-jre11-temurin@sha256:bf23f2dffde0c1b6ef6eaba95e05f531a3a6f274c5234d10126d73b092db18b6
# Valid for arm64:
# FROM tomcat:9-jre11-temurin@sha256:87d94e757ccd243c9f277ae6fd362bd1c718446599fb36acd8f93c1af3efaf61
#9.0-jre11-slim
#9.0.65-jdk11-openjdk-slim
MAINTAINER thinkWhere<info@thinkwhere.com>
# Credit: Tim Sutton<tim@linfiniti.com>
# kartoza/docker-geoserver

RUN apt-get clean; apt-get update --fix-missing; apt-get -y install libapr1-dev \
    libssl-dev wget zip curl xsltproc certbot cabextract

RUN set -e \
    export DEBIAN_FRONTEND=noninteractive \
    dpkg-divert --local --rename --add /sbin/initctl \
	# Set JAVA_HOME to /usr/lib/jvm/default-java and link it to OpenJDK installation
#    && ln -s /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/default-java \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*


#-------------Application Specific Stuff ----------------------------------------------------

ENV DEBIAN_FRONTEND=noninteractive \
    GEOSERVER_DATA_DIR=/opt/geoserver/data_dir \
	GDAL_SKIP="ECW JP2ECW" \
	GDAL_DATA=/usr/local/gdal-data \
	# AMD64 architecture:
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/apr/lib:/usr/lib:/usr/lib/x86_64-linux-gnu"
	# ARM64 architecture:
	# LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/apr/lib:/usr/lib:/usr/lib/aarch64-linux-gnu"


RUN mkdir -p ${GEOSERVER_DATA_DIR}

ADD resources /tmp/resources

# Optionally remove Tomcat manager, docs, and examples
ARG TOMCAT_EXTRAS=false
RUN if [ "$TOMCAT_EXTRAS" = false ]; then \
    rm -rf $CATALINA_HOME/webapps/ROOT && \
    rm -rf $CATALINA_HOME/webapps/docs && \
    rm -rf $CATALINA_HOME/webapps/examples && \
    rm -rf $CATALINA_HOME/webapps/host-manager && \
    rm -rf $CATALINA_HOME/webapps/manager; \
  fi;

# ---------- GS_Version will be passed in as a parameter ------------
ARG GS_VERSION

# Add GDAL native libraries if the build-arg GDAL_NATIVE = true
# EWC and JP2ECW are subjected to licence restrictions
ARG GDAL_NATIVE=false
RUN if [ "$GDAL_NATIVE" = true ]; then \
    wget --progress=bar http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.16/native/gdal/gdal-data.zip \
	-O /tmp/resources/gdal-data.zip && \
    wget --progress=bar http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.29/native/gdal/linux/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz \
	-O /tmp/resources/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz && \
    unzip /tmp/resources/gdal-data.zip -d /usr/local && \
    mkdir /usr/local/gdal_native_libs && \
    tar -xvf /tmp/resources/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz -C /usr/local/gdal_native_libs; \
    apt-get update; \
	apt-get install -y gdal-bin --fix-missing; \
fi;


# If using GDAL make sure extension is downloaded
RUN if [ "$GDAL_NATIVE" = true ] && [ ! -f /tmp/resources/plugins/geoserver-gdal-plugin.zip ]; then \
	wget --progress=bar -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-gdal-plugin.zip \
	-O /tmp/resources/plugins/geoserver-gdal-plugin.zip; \
fi;

WORKDIR $CATALINA_HOME


# Fetch the geoserver war file if it
# is not available locally in the resources dir and
RUN if [ ! -f /tmp/resources/geoserver.zip ]; then \
    wget --progress=bar -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/geoserver-${GS_VERSION}-war.zip \
      -O /tmp/resources/geoserver.zip; \
    fi; \
    unzip /tmp/resources/geoserver.zip -d /tmp/geoserver \
    && unzip /tmp/geoserver/geoserver.war -d $CATALINA_HOME/webapps/geoserver \
    && rm -rf $CATALINA_HOME/webapps/geoserver/data \
    && rm -rf /tmp/geoserver

# Install any plugin zip files in resources/plugins
RUN if ls /tmp/resources/plugins/*.zip > /dev/null 2>&1; then \
      for p in /tmp/resources/plugins/*.zip; do \
        unzip $p -d /tmp/gs_plugin \
        && mv /tmp/gs_plugin/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
        && rm -rf /tmp/gs_plugin; \
      done; \
    fi;

# Install Font files in resources/fonts if they exist
RUN if ls /tmp/resources/fonts/*.ttf > /dev/null 2>&1; then \
      cp -rf /tmp/resources/fonts/*.ttf /usr/share/fonts/truetype/; \
	fi;

# Copy across script and XML stylesheet which will allow the Tomcat server.xml to be parameterised
RUN cp /tmp/resources/tomcat/* $CATALINA_HOME/conf/
RUN chmod +x $CATALINA_HOME/conf/update_tomcat_settings.sh

# Delete resources after installation
RUN rm -rf /tmp/resources

# CMD "/opt/geoserver/bin/startup.sh"
EXPOSE 8080