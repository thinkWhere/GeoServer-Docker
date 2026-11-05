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

# GS_VERSION can be passed as first arg; fallback to config value.
GS_VERSION="${1:-$(cfg_get gs_version)}"
# Minor series, e.g. 3.0.1 -> 3.0 ; used for the build.geoserver.org paths.
BUILD_GS_VERSION=${GS_VERSION%.*}
PLUGINS_CSV=$(cfg_get plugins)
COMMUNITY_PLUGINS_CSV=$(cfg_get community_plugins)

IFS=',' read -r -a plugins <<< "$PLUGINS_CSV"
IFS=',' read -r -a community_plugins <<< "$COMMUNITY_PLUGINS_CSV"

echo "Build ${GS_VERSION}"
echo "Build minor ${BUILD_GS_VERSION}"

mkdir -p ./resources/plugins

# ---------------------------------------------------------------------------
# Version guard.
# Plugin zips are cached under resources/plugins with version-less names
# (geoserver-css-plugin.zip). Without this guard a cache left over from a
# previous GeoServer release would silently be baked into the new image.
# ---------------------------------------------------------------------------
STAMP_FILE=./resources/plugins/.gs_version
CACHED_VERSION=""
if [ -f "$STAMP_FILE" ]
then
	CACHED_VERSION=$(cat "$STAMP_FILE")
fi

if [ "$CACHED_VERSION" != "$GS_VERSION" ]
then
	if ls ./resources/plugins/*.zip > /dev/null 2>&1
	then
		echo "Cached plugins are for GeoServer '${CACHED_VERSION:-unknown}'; purging for ${GS_VERSION}."
		rm -f ./resources/plugins/*.zip
	fi
fi
echo "$GS_VERSION" > "$STAMP_FILE"

# Remove cached zips for plugins that are no longer in the configured lists,
# otherwise the Dockerfile (which installs every zip in resources/plugins)
# would still bake them into the image.
WANTED=$(printf '%s\n' "${plugins[@]}" "${community_plugins[@]}" | xargs -n1 2>/dev/null | sed '/^$/d')
for z in ./resources/plugins/*.zip
do
	[ -e "$z" ] || continue
	name=$(basename "$z" .zip)
	name=${name#geoserver-}
	name=${name%-plugin}
	if ! echo "$WANTED" | grep -qx "$name"
	then
		echo "Removing unconfigured cached plugin: $(basename "$z")"
		rm -f "$z"
	fi
done

# Stable extensions are published on SourceForge per release.
for p in "${plugins[@]}"
do
	p=$(echo "$p" | xargs)
	[ -z "$p" ] && continue
	if [ ! -s resources/plugins/geoserver-${p}-plugin.zip ]
	then
		wget https://sourceforge.net/projects/geoserver/files/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-${p}-plugin.zip/download -O resources/plugins/geoserver-${p}-plugin.zip
		echo "geoserver-${p}-plugin downloaded."
	else
		echo "Skipping existing plugin: geoserver-${p}-plugin.zip"
	fi
done

# ---------------------------------------------------------------------------
# Community plugins are not available from SourceForge; they come from the
# nightly builds at build.geoserver.org.
#
# The snapshot version in the file name does NOT match gs_version and differs
# per branch (2.28.x publishes geoserver-2.28-SNAPSHOT-*, while 3.0.x publishes
# geoserver-3.0.3-SNAPSHOT-*), so resolve the real file name from the directory
# index instead of guessing it.
# ---------------------------------------------------------------------------
COMMUNITY_URL="https://build.geoserver.org/geoserver/${BUILD_GS_VERSION}.x/community-latest"
COMMUNITY_INDEX=""

resolve_community_file() {
	local name="$1"
	if [ -z "$COMMUNITY_INDEX" ]
	then
		COMMUNITY_INDEX=$(wget -q -O - "${COMMUNITY_URL}/" || true)
	fi
	echo "$COMMUNITY_INDEX" \
		| grep -o "geoserver-[0-9][0-9.]*-SNAPSHOT-${name}-plugin\.zip" \
		| head -n 1
}

for c in "${community_plugins[@]}"
do
	c=$(echo "$c" | xargs)
	[ -z "$c" ] && continue
	if [ -s resources/plugins/geoserver-${c}-plugin.zip ]
	then
		echo "Skipping existing community plugin: geoserver-${c}-plugin.zip"
		continue
	fi

	remote_file=$(resolve_community_file "$c")
	if [ -z "$remote_file" ]
	then
		echo "ERROR: community plugin '${c}' not found at ${COMMUNITY_URL}/" >&2
		exit 1
	fi

	wget "${COMMUNITY_URL}/${remote_file}" -O resources/plugins/geoserver-${c}-plugin.zip
	echo "${remote_file} downloaded as geoserver-${c}-plugin.zip."
done
