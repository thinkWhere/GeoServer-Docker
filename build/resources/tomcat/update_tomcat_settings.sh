#!/bin/bash

# Update Tomcat server settings
# Inspired by https://github.com/kartoza/docker-geoserver

# Backup Tomcat server config before making any changes
cp ${CATALINA_HOME}/conf/server.xml ${CATALINA_HOME}/conf/server_backup.xml

# Setup any variables which have been passed into the build
if [ -n "$HTTP_PORT" ]; then
  HTTP_PORT_PARAM="--stringparam http.port $HTTP_PORT "
fi

if [ -n "$HTTP_PROXY_NAME" ]; then
  HTTP_PROXY_NAME_PARAM="--stringparam http.proxyName $HTTP_PROXY_NAME "
fi

if [ -n "$HTTP_PROXY_PORT" ]; then
  HTTP_PROXY_PORT_PARAM="--stringparam http.proxyPort $HTTP_PROXY_PORT "
fi

if [ -n "$HTTP_REDIRECT_PORT" ]; then
  HTTP_REDIRECT_PORT_PARAM="--stringparam http.redirectPort $HTTP_REDIRECT_PORT "
fi

if [ -n "$HTTP_CONNECTION_TIMEOUT" ]; then
  HTTP_CONNECTION_TIMEOUT_PARAM="--stringparam http.connectionTimeout $HTTP_CONNECTION_TIMEOUT "
fi

if [ -n "$HTTP_COMPRESSION" ]; then
  HTTP_COMPRESSION_PARAM="--stringparam http.compression $HTTP_COMPRESSION "
fi

if [ -n "$HTTP_MAX_HEADER_SIZE" ]; then
  HTTP_MAX_HEADER_SIZE_PARAM="--stringparam http.maxHttpHeaderSize $HTTP_MAX_HEADER_SIZE "
fi

if [ -n "$HTTPS_PORT" ]; then
  HTTPS_PORT_PARAM="--stringparam https.port $HTTPS_PORT "
fi

if [ -n "$HTTPS_MAX_THREADS" ]; then
  HTTPS_MAX_THREADS_PARAM="--stringparam https.maxThreads $HTTPS_MAX_THREADS "
fi

if [ -n "$HTTPS_CLIENT_AUTH" ]; then
  HTTPS_CLIENT_AUTH_PARAM="--stringparam https.clientAuth $HTTPS_CLIENT_AUTH "
fi

if [ -n "$HTTPS_PROXY_NAME" ]; then
  HTTPS_PROXY_NAME_PARAM="--stringparam https.proxyName $HTTPS_PROXY_NAME "
fi

if [ -n "$HTTPS_PROXY_PORT" ]; then
  HTTPS_PROXY_PORT_PARAM="--stringparam https.proxyPort $HTTPS_PROXY_PORT "
fi

if [ -n "$HTTPS_COMPRESSION" ]; then
  HTTPS_COMPRESSION_PARAM="--stringparam https.compression $HTTPS_COMPRESSION "
fi

if [ -n "$HTTPS_MAX_HEADER_SIZE" ]; then
  HTTPS_MAX_HEADER_SIZE_PARAM="--stringparam https.maxHttpHeaderSize $HTTPS_MAX_HEADER_SIZE "
fi

if [ -n "$JKS_FILE" ]; then
  JKS_FILE_PARAM="--stringparam https.keystoreFile ${CERT_DIR}/$JKS_FILE "
fi
if [ -n "$JKS_KEY_PASSWORD" ]; then
  JKS_KEY_PASSWORD_PARAM="--stringparam https.keystorePass $JKS_KEY_PASSWORD "
fi

if [ -n "$KEY_ALIAS" ]; then
  KEY_ALIAS_PARAM="--stringparam https.keyAlias $KEY_ALIAS "
fi

if [ -n "$JKS_STORE_PASSWORD" ]; then
  JKS_STORE_PASSWORD_PARAM="--stringparam https.keyPass $JKS_STORE_PASSWORD "
fi

# Parse XML using xsltproc to insert variables into server.xml
transform="xsltproc \
  --output ${CATALINA_HOME}/conf/server.xml \
  $HTTP_PORT_PARAM \
  $HTTP_PROXY_NAME_PARAM \
  $HTTP_PROXY_PORT_PARAM \
  $HTTP_REDIRECT_PORT_PARAM \
  $HTTP_CONNECTION_TIMEOUT_PARAM \
  $HTTP_COMPRESSION_PARAM \
  $HTTP_MAX_HEADER_SIZE_PARAM \
  $HTTPS_PORT_PARAM \
  $HTTPS_MAX_THREADS_PARAM \
  $HTTPS_CLIENT_AUTH_PARAM \
  $HTTPS_PROXY_NAME_PARAM \
  $HTTPS_PROXY_PORT_PARAM \
  $HTTPS_COMPRESSION_PARAM \
  $HTTPS_MAX_HEADER_SIZE_PARAM \
  $JKS_FILE_PARAM \
  $JKS_KEY_PASSWORD_PARAM \
  $KEY_ALIAS_PARAM \
  $JKS_STORE_PASSWORD_PARAM \
  ${CATALINA_HOME}/conf/tomcat_server_stylesheet.xsl \
  ${CATALINA_HOME}/conf/server.xml"

eval "$transform"

# Run server
. $CATALINA_HOME/bin/catalina.sh run
