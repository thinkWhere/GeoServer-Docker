# Running the GeoServer image locally

Step-by-step guide for pulling the published image from Docker Hub and running
it on your own machine against a data directory you control.

This guide assumes the image has already been built and pushed by the GitHub
Actions workflow.

- **Image:** `thinkwhere/geoserver`
- **Tag:** `<geoserver-version>-<arch>` — e.g. `3.0.1-arm64` (ARM64) or
  `3.0.1-amd64` (x86-64)
- **GeoServer:** 3.0.1 on Tomcat 11 / Java 21, with GDAL 3.8.4 native support

---

## 1. Prerequisites

- Docker Desktop (Windows/macOS) or Docker Engine (Linux), running.
- Roughly 3 GB of free disk space for the image.
- Confirm Docker is up:

```bash
docker version
```

---

## 2. Check which tag you need

The image is tagged per architecture. Find your machine's architecture:

```bash
docker info --format '{{.Architecture}}'
```

| Output | Use tag |
| --- | --- |
| `aarch64` / `arm64` | `3.0.1-arm64` |
| `x86_64` | `3.0.1-amd64` |

To see what is actually published, browse
<https://hub.docker.com/r/thinkwhere/geoserver/tags>.

> Running an `arm64` image on an `amd64` host (or the reverse) works only through
> QEMU emulation and is slow — GDAL-heavy rendering especially. Match the tag to
> your hardware.

---

## 3. Pull the image

```bash
docker pull thinkwhere/geoserver:3.0.1-arm64
```

If Docker picks the wrong architecture (common on Apple Silicon with multi-arch
tags), force it:

```bash
docker pull --platform linux/arm64 thinkwhere/geoserver:3.0.1-arm64
```

Verify it arrived:

```bash
docker image inspect thinkwhere/geoserver:3.0.1-arm64 \
  --format 'arch={{.Architecture}} size={{.Size}}'
```

---

## 4. Choose and prepare a data directory

The container stores **all** GeoServer configuration, styles, workspaces, layers
and logs in `/opt/geoserver/data_dir`. Bind-mount a folder from your own disk
there so your configuration survives container restarts and image upgrades.

Pick any location you like, for example:

| OS | Example path |
| --- | --- |
| Linux / macOS | `~/geoserver_data` |
| Windows (PowerShell / CMD) | `C:\geoserver_data` |

### Option A — start empty (recommended)

GeoServer populates a fresh, minimal data directory on first start.

```bash
mkdir -p ~/geoserver_data
```

```powershell
mkdir C:\geoserver_data
```

### Option B — start from the official sample data directory

If you want the sample layers (`sf`, `topp`, `nurc`, `tiger`, the ArcGrid and
mosaic coverages) to exercise WMS/WFS straight away, seed the folder from the
GeoServer binary distribution:

1. Download `geoserver-3.0.1-bin.zip` from the GeoServer download page for
   version 3.0.1.
2. Unzip it.
3. Copy the `data_dir` folder out of the unzipped archive into your chosen
   location, so you end up with `~/geoserver_data/global.xml`,
   `~/geoserver_data/workspaces/`, and so on.

> Use a data directory created by the **same** GeoServer version, or one you
> have deliberately upgraded. Pointing 3.0.1 at a much older data directory
> triggers an in-place upgrade that is not reversible — take a copy first.

### Option C — reuse an existing data directory

Point the mount at it directly. **Back it up first**, because GeoServer will
upgrade its format on start if it came from an earlier version.

---

## 5. Run the container

Replace the data directory path with your own.

### Linux / macOS

```bash
docker run -d \
  --name geoserver_local \
  -p 8085:8080 \
  -v "$HOME/geoserver_data:/opt/geoserver/data_dir" \
  -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" \
  thinkwhere/geoserver:3.0.1-arm64
```

### Windows (PowerShell)

```powershell
docker run -d `
  --name geoserver_local `
  -p 8085:8080 `
  -v "C:\geoserver_data:/opt/geoserver/data_dir" `
  -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" `
  thinkwhere/geoserver:3.0.1-arm64
```

### Windows (CMD, single line)

```bat
docker run -d --name geoserver_local -p 8085:8080 -v "C:\geoserver_data:/opt/geoserver/data_dir" -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" thinkwhere/geoserver:3.0.1-arm64
```

What the flags do:

| Flag | Purpose |
| --- | --- |
| `-d` | run detached, in the background |
| `--name geoserver_local` | a stable name for `logs` / `stop` / `rm` |
| `-p 8085:8080` | publish the container's Tomcat port on host port 8085 |
| `-v <host>:/opt/geoserver/data_dir` | your data directory |
| `-e GEOSERVER_LOG_LOCATION` | in GeoServer 3.x the log path is set **only** by this environment variable (or a system property) — the Admin Console and REST options for it were removed |

### Running with custom Tomcat settings

To parameterise `server.xml` (proxy name, header size, HTTPS, timeouts), start
the container through the settings script instead of the default entrypoint and
pass the matching environment variables:

```bash
docker run -d \
  --name geoserver_local \
  -p 8085:8080 \
  -v "$HOME/geoserver_data:/opt/geoserver/data_dir" \
  -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" \
  -e "HTTP_MAX_HEADER_SIZE=524288" \
  thinkwhere/geoserver:3.0.1-arm64 \
  /bin/sh -c conf/update_tomcat_settings.sh
```

Supported variables include `HTTP_PORT`, `HTTP_PROXY_NAME`, `HTTP_PROXY_PORT`,
`HTTP_CONNECTION_TIMEOUT`, `HTTP_COMPRESSION`, `HTTP_MAX_HEADER_SIZE`,
`HTTPS_PORT`, `HTTPS_MAX_THREADS`, `HTTPS_CLIENT_AUTH`, `HTTPS_PROXY_NAME`,
`HTTPS_PROXY_PORT`, `JKS_FILE`, `JKS_KEY_PASSWORD`, `KEY_ALIAS`,
`JKS_STORE_PASSWORD`.

### Behind a reverse proxy

GeoServer 3.0 only trusts `X-Forwarded-For` from a proxy on the local host. For
a proxy elsewhere, add:

```bash
  -e "GEOSERVER_TRUSTED_PROXIES=10.0.0.5"
```

---

## 6. Watch it start

```bash
docker logs -f geoserver_local
```

First start takes roughly 30–90 seconds. Wait for a line like:

```
org.apache.catalina.startup.Catalina.start Server startup in [nnnnn] milliseconds
```

Press `Ctrl+C` to stop following the logs — the container keeps running.

Confirm it is up:

```bash
docker ps --filter name=geoserver_local
```

---

## 7. Open GeoServer

<http://localhost:8085/geoserver>

Default credentials on a fresh data directory:

- **User:** `admin`
- **Password:** `geoserver`

> Change the password immediately via *Security → Users, Groups, Roles*, even
> for a local instance.

---

## 8. Verify the build

### Services respond

```bash
curl -s "http://localhost:8085/geoserver/ows?service=WMS&version=1.3.0&request=GetCapabilities" | head -5
```

### Extensions are loaded

In the web interface:

| Plugin | Where to look |
| --- | --- |
| control-flow | *Status → Modules* lists `gs-control-flow` |
| css | *Styles → Add a new style* offers the **CSS** format |
| monitor | a **Monitor** section appears in the left menu |
| gwc-s3 | *Tile Caching → Blobstores → Add* offers **S3 BlobStore** |
| vectortiles | *Layer → Publishing → WMS Settings* offers MVT / GeoJSON / TopoJSON formats |
| ogcapi-features | <http://localhost:8085/geoserver/ogc/features/v1> returns a landing page |
| cog-s3 (community) | *Stores → Add new store* offers **GeoTIFF** with a **Cloud Optimized GeoTIFF** / S3 range reader option |

### Raster formats

*Stores → Add new store* should list **ArcGrid**, **WorldImage** (from the
`image` extension), and the GDAL-backed formats (**EHdr**, **ENVIHdr**,
**ERDASImg**, **NITF**, **VRT**, **DTED**, **AIG**, …).

### GDAL native libraries

The GDAL formats only appear when the native libraries loaded. Check inside the
container:

```bash
docker exec geoserver_local gdalinfo --version
docker exec geoserver_local ls /usr/lib/jni
```

You should see GDAL 3.8.x and `libgdalalljni.so`. Also check
*Status → Modules → gs-gdal*, and search the GeoServer log for `GDAL`:

```bash
docker exec geoserver_local sh -c 'grep -i gdal /opt/geoserver/data_dir/logs/*.log | head'
```

---

## 9. Everyday commands

```bash
# stop
docker stop geoserver_local

# start again (configuration persists in your data directory)
docker start geoserver_local

# follow logs
docker logs -f geoserver_local

# shell inside the container
docker exec -it geoserver_local bash

# remove the container (your data directory is untouched)
docker rm -f geoserver_local
```

### Upgrading to a newer image

```bash
docker rm -f geoserver_local
docker pull thinkwhere/geoserver:<new-tag>
# re-run the docker run command from step 5 with the new tag
```

Back up your data directory before upgrading across GeoServer versions.

### Running two instances side by side

Use different host ports, container names **and** data directories:

```bash
docker run -d --name geoserver_8086 -p 8086:8080 \
  -v "$HOME/geoserver_data_b:/opt/geoserver/data_dir" \
  -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8086.log" \
  thinkwhere/geoserver:3.0.1-arm64
```

---

## 10. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `port is already allocated` | Another process holds 8085. Use `-p 8090:8080` instead. |
| 404 at `/geoserver` | Still starting, or startup failed. Check `docker logs geoserver_local`. |
| Container exits immediately | Usually a data directory permission problem. On Linux the Tomcat user must be able to write the mounted folder (`chmod -R a+rwX ~/geoserver_data`). |
| Empty folder on Windows, nothing written | The drive is not shared with Docker Desktop: *Settings → Resources → File sharing*. |
| GDAL formats missing from the store list | Native libraries did not load — run the checks in step 8 and look for `UnsatisfiedLinkError` in the log. |
| Very slow rendering, high CPU | Architecture mismatch; you are running under QEMU emulation. Pull the tag matching `docker info --format '{{.Architecture}}'`. |
| `Could not acquire lock` / corrupt catalog | Two containers are mounting the same data directory. Give each its own. |
| Login fails on an existing data directory | Credentials come from the data directory's `security/` folder, not the image. |
