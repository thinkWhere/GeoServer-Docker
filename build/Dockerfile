#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
ARG GDAL_VERSION
ARG TOMCAT_IMAGE
FROM ghcr.io/osgeo/gdal:ubuntu-full-${GDAL_VERSION} AS gdal-builder

# GeoServer 3.x requires Jakarta EE Servlet 6.1 => Tomcat 11.0.x, and Java 17+.
# TOMCAT_IMAGE is set in build-config.yml (e.g. 11.0.27-jdk21-temurin-noble).
# The tomcat image is multi-arch, so this builds for amd64 and arm64 alike;
# pick the target with --platform (see build.sh / build-config.yml).
FROM tomcat:${TOMCAT_IMAGE}
LABEL maintainer="thinkWhere <info@thinkwhere.com>"
# Credit: Tim Sutton<tim@linfiniti.com>
# kartoza/docker-geoserver

RUN apt-get clean; apt-get update --fix-missing; apt-get -y install libapr1-dev \
    libssl-dev wget zip unzip curl xsltproc certbot cabextract

RUN set -e \
    export DEBIAN_FRONTEND=noninteractive \
    dpkg-divert --local --rename --add /sbin/initctl \
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
      'export JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true"' \
      > "$CATALINA_HOME/bin/setenv.sh"; \
    chmod +x "$CATALINA_HOME/bin/setenv.sh"

# resources/data_dir is excluded via .dockerignore (runtime bind-mount only).
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
# The JNI bindings (libgdalalljni.so) and gdal.jar are taken from the
# ghcr.io/osgeo/gdal image; `gdal-bin` comes from the distro of the tomcat
# base image. Keep GDAL_VERSION aligned with that distro's GDAL
# (Ubuntu 24.04 "noble" => GDAL 3.8.4) so the native library versions match.
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
        unzip -o $p -d /tmp/gs_plugin \
        && mv -f /tmp/gs_plugin/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
        && rm -rf /tmp/gs_plugin; \
      done; \
    fi;

# ---------------------------------------------------------------------------
# Align the GDAL SWIG bindings jar with the native libraries.
#
# The GeoServer gdal extension bundles gdal-3.2.0.jar, but the JNI .so files
# installed above come from GDAL ${GDAL_VERSION}. GeoServer's own docs require
# the bindings jar to match the installed GDAL, so drop the bundled jar and use
# the gdal.jar shipped by the osgeo/gdal image instead.
# ---------------------------------------------------------------------------
RUN if [ "$GDAL_NATIVE" = true ] && [ -f /usr/share/java/gdal.jar ]; then \
      rm -f $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/gdal-*.jar; \
      cp /usr/share/java/gdal.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/gdal.jar; \
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

EXPOSE 8080
