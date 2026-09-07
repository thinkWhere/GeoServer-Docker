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
docker run --name geoserver_local -p 8085:8080 -d -v "C:\data\DATA_TEAM\geoserver_upgrade\generation_of_images\GeoServer-Docker\build\resources\data_dir:/opt/geoserver/data_dir" -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" thinkwhere/geoserver:2.28.4
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

