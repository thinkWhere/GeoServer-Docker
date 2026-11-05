# docker-geoserver

Container image build for thinkWhere GeoServer deployments.

This repository now uses a config-driven build flow so version and plugin updates are made in one place.

## What this repo builds

The image is built from:

- Tomcat base image (configurable)
- GeoServer WAR (configurable version)
- Stable and community GeoServer plugins (configurable lists)
- Optional GDAL native support and GDAL GeoServer extension
- Optional custom fonts from `build/resources/fonts`

Main build files:

- `build/build-config.yml` (single source of build values)
- `build/build.sh` (Linux/macOS local build)
- `build/build.bat` (Windows local build)
- `build/Dockerfile` (image recipe)
- `build/download.sh` (plugin download helper used by GitHub Actions)

## Central config file

Update only `build/build-config.yml` for normal version/plugin changes.

Keys:

- `gs_version`
- `tomcat_image`
- `gdal_version`
- `gdal_native`
- `tomcat_extras`
- `build_platform`
- `plugins` (comma-separated stable plugins)
- `community_plugins` (comma-separated community plugins)

ARM64 example values are included as comments in the same file.

## Local build

### Windows

1. Open PowerShell.
2. Go to `build` folder.
3. Run `build.bat`.

```powershell
Set-Location "C:\data\DATA_TEAM\geoserver_upgrade\generation_of_images\GeoServer-Docker\build"
.\build.bat
```

### Linux/macOS

1. Open shell.
2. Go to `build` folder.
3. Run `build.sh`.

```bash
cd build
chmod +x build.sh
./build.sh
```

Important:

- Both scripts build locally only (`docker build`), they do not push images.
- If plugin ZIP files already exist in `build/resources/plugins`, scripts skip re-download.

## Run container locally

Windows example with repo-local data directory:

```powershell
docker rm -f geoserver_local 2>$null
docker run --name geoserver_local -p 8085:8080 -d -v "C:\data\DATA_TEAM\geoserver_upgrade\AMI\generation_of_images\GeoServer-Docker\build\resources\data_dir:/opt/geoserver/data_dir" -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" thinkwhere/geoserver:3.0.1
```

Open:

- `http://localhost:8085/geoserver`

## Deprecated files

- `docker-compose.deprecated.yml` is legacy reference only and is not part of the current build/deploy flow.

## Nginx config (testing only)

- `nginx/nginx-for-testing.conf` is a local/deprecated testing config for a separate `nginx` container.
- It is not packaged into the `thinkwhere/geoserver` image.
- The GeoServer image build context is `build/`, so files under `nginx/` are excluded from image builds.

## Step-by-step: upgrade GeoServer version

Use this process when preparing a new image release.

1. Edit `build/build-config.yml`.
2. Set `gs_version` to the new GeoServer version.
3. Review `plugins` and `community_plugins` lists and adjust as needed for that version.
4. If needed, update `tomcat_image`, `gdal_version`, and `gdal_native`.
5. Run local build (`build.bat` on Windows or `build.sh` on Linux).
6. Run a local container and verify GeoServer starts and required plugins load.
7. Commit and push your changes to `master`.

## Step-by-step: what GitHub Actions does

Workflow file: `.github/workflows/main.yml`.

On push to `master`, GitHub Actions does this:

1. Checks out the repository.
2. Logs in to Docker Hub using repository secrets:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`
3. Sets up QEMU and Buildx for multi-arch builds.
4. Runs `build/download.sh <gs-version>` to fetch plugin ZIP files into `build/resources/plugins`.
5. Builds the image from `build/Dockerfile` using matrix build args (GeoServer version, Tomcat image, GDAL settings).
6. Pushes the image to Docker Hub under `thinkwhere/geoserver:<tag>`.

## Step-by-step: how to publish a new Docker Hub tag

1. Open `.github/workflows/main.yml`.
2. In the matrix entry, update:
   - `tag`
   - `gs-version`
   - (optional) `tomcat-image`, `gdal-version`, `gdal-native`, `tomcat-extras`, `platform`
3. Ensure `build/build-config.yml` plugin lists are compatible with that GeoServer version.
4. Commit and push to `master`.
5. Watch the workflow run in GitHub Actions.
6. Confirm the new tag appears on Docker Hub (`thinkwhere/geoserver`).

## Notes

- `GDAL_NATIVE=true` installs/copies GDAL native dependencies and ensures GDAL extension ZIP is available during build.
- `GDAL_NATIVE=false` skips GDAL native setup and skips GDAL extension auto-download.
- Local scripts and CI both rely on build args and config-driven values to avoid hardcoded updates in multiple places.


## Version compatibility (GeoServer 3.0.1)

GeoServer 3.0 moved to Jakarta EE Servlet 6.1. This constrains the stack:

| Component | Value | Why |
| --- | --- | --- |
| GeoServer | `3.0.1` | `geoserver-3.0.1-war.zip` on SourceForge |
| Servlet container | Tomcat **11.0.x** | Tomcat 9 and 10.1 are **not supported** by GeoServer 3.x |
| Java | **21** (17 is the minimum) | base image `tomcat:11.0.27-jdk21-temurin-noble` |
| GDAL | `3.8.4` | the Tomcat image is Ubuntu 24.04 "noble", whose `gdal-bin` package is 3.8.4 — the JNI libraries copied from `ghcr.io/osgeo/gdal:ubuntu-full-3.8.4` must match it |

GeoServer 3.0.1 uses GeoTools 35.1 / ImageIO-Ext 2.1.1, which is tested against
GDAL 3.x. The gdal extension bundles `gdal-3.2.0.jar`; the Dockerfile replaces
it with the `gdal.jar` from the osgeo image so the Java bindings match the
installed native libraries, as GeoServer's documentation requires.

Both the Tomcat and osgeo/gdal base images publish `linux/arm64` variants, so
`build_platform: linux/arm64/v8` builds cleanly.

### Plugins built into the image

Official extensions: `control-flow`, `css`, `monitor`, `gwc-s3`, `vectortiles`,
`ogcapi-features`, `gdal`, `image`, `arcgrid`.

Community: `cog-s3`.

Community plugin file names do **not** follow `gs_version`: the `3.0.x`
nightly directory publishes `geoserver-3.0.3-SNAPSHOT-<name>-plugin.zip`
(the `2.28.x` branch published `geoserver-2.28-SNAPSHOT-<name>-plugin.zip`).
`download.sh` therefore resolves the real file name from the directory index
rather than constructing it.

### About `build/resources/data_dir`

This is **not** part of the image build. It is the stock GeoServer sample data
directory, bind-mounted at runtime by `run.sh` / `run.bat` for local smoke
testing (`-v .../data_dir:/opt/geoserver/data_dir`). It is untracked in git and
is excluded from the Docker build context via `build/.dockerignore`.

## Running the published image locally

See [RUN_LOCALLY.md](RUN_LOCALLY.md) for a step-by-step guide to pulling the
image from Docker Hub and running it against your own data directory.
