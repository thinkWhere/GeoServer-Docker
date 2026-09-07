#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
ARG GDAL_VERSION
ARG TOMCAT_IMAGE
FROM ghcr.io/osgeo/gdal:ubuntu-full-${GDAL_VERSION} AS gdal-builder

# Defaults to amd64:
FROM tomcat:${TOMCAT_IMAGE}
# Valid for arm64:
# FROM tomcat:9-jre11-temurin@sha256:96f05b79814a1fb0523e3063668b4e3be7a1bbb01e6e6b2757915764381825ac
#9.0-jre11-slim
#9.0.65-jdk11-openjdk-slim
LABEL maintainer="thinkWhere <info@thinkwhere.com>"
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
    GDAL_DATA=/usr/local/gdal-data \
    LD_LIBRARY_PATH_BASE="/usr/lib/jni:/usr/local/apr/lib:/usr/lib"


RUN mkdir -p ${GEOSERVER_DATA_DIR}

ARG TARGETARCH
RUN set -e; \
    ARCH_LIB_DIR="/usr/lib/x86_64-linux-gnu"; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
      arm64|aarch64) ARCH_LIB_DIR="/usr/lib/aarch64-linux-gnu" ;; \
      amd64|x86_64) ARCH_LIB_DIR="/usr/lib/x86_64-linux-gnu" ;; \
      *) echo "Unknown architecture '${TARGETARCH:-$(dpkg --print-architecture)}', defaulting to amd64 library path" ;; \
    esac; \
    printf '%s\n' \
      '#!/bin/sh' \
      "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH:+\${LD_LIBRARY_PATH}:}${LD_LIBRARY_PATH_BASE}:${ARCH_LIB_DIR}" \
      > "$CATALINA_HOME/bin/setenv.sh"; \
    chmod +x "$CATALINA_HOME/bin/setenv.sh"

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
ARG GDAL_NATIVE=true

# GDAL support is optional and enabled with build-arg GDAL_NATIVE=true.
RUN --mount=from=gdal-builder,source=/usr/share/java,target=/tmp/gdal-builder-java \
        --mount=from=gdal-builder,source=/usr/lib,target=/tmp/gdal-builder-lib \
        if [ "$GDAL_NATIVE" = true ]; then \
            cp -a /tmp/gdal-builder-java/. /usr/share/java/ \
            && mkdir -p /usr/lib/jni \
            && find /tmp/gdal-builder-lib -path "*/jni/*" -type f -exec cp {} /usr/lib/jni/ \; \
            && apt-get update \
            && apt-get install -y gdal-bin --fix-missing \
            && ldconfig; \
        fi

# If GDAL native support is enabled, ensure GDAL extension is available.
RUN if [ "$GDAL_NATIVE" = true ] && [ ! -f /tmp/resources/plugins/geoserver-gdal-plugin.zip ]; then \
    wget --progress=bar -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-gdal-plugin.zip \
    -O /tmp/resources/plugins/geoserver-gdal-plugin.zip; \
fi

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