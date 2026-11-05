#!/bin/bash

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-./build-config.yml}"

if [ ! -f "$CONFIG_FILE" ]
then
	echo "Config file not found: $CONFIG_FILE"
	exit 1
fi

cfg_get() {
	local key="$1"
	local value
	value=$(grep -E "^${key}:" "$CONFIG_FILE" | head -n 1 | sed -E "s/^${key}:[[:space:]]*//")
	value=${value//\"/}
	value=${value//\'/}
	echo "$value"
}

GS_VERSION=$(cfg_get gs_version)
TOMCAT_IMAGE=$(cfg_get tomcat_image)
GDAL_VERSION=$(cfg_get gdal_version)
GDAL_NATIVE=$(cfg_get gdal_native)
TOMCAT_EXTRAS=$(cfg_get tomcat_extras)
BUILD_PLATFORM=$(cfg_get build_platform)

# Fetch the GeoServer extension / community plugin zips.
# Single source of truth: download.sh (also used by the GitHub workflow).
CONFIG_FILE="$CONFIG_FILE" bash ./download.sh "${GS_VERSION}"

## build options include:
#    TOMCAT_EXTRAS  [true | false]
#    GDAL_NATIVE    [true | false]  - build with GDAL native support
#    GS_VERSION                     - which version of GeoServer is built
#    TOMCAT_IMAGE                   - base tomcat tag (must be Tomcat 11 for GeoServer 3.x)
#    GDAL_VERSION                   - ghcr.io/osgeo/gdal tag supplying the JNI bindings

# buildx is required for cross-platform builds (e.g. linux/arm64/v8 on an amd64 host).
docker buildx build \
	--platform "${BUILD_PLATFORM}" \
	--build-arg GS_VERSION="${GS_VERSION}" \
	--build-arg TOMCAT_IMAGE="${TOMCAT_IMAGE}" \
	--build-arg GDAL_VERSION="${GDAL_VERSION}" \
	--build-arg TOMCAT_EXTRAS="${TOMCAT_EXTRAS}" \
	--build-arg GDAL_NATIVE="${GDAL_NATIVE}" \
	--load \
	-t thinkwhere/geoserver:"${GS_VERSION}" \
	.

# To push a multi-arch / remote image instead of loading it locally,
# replace --load with --push above.
