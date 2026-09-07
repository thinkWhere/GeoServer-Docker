# GeoServer Docker Release Playbook

A practical, human-friendly guide for publishing a new `thinkwhere/geoserver` image.

## Release Flow At A Glance

1. Choose the target version and platform.
2. Update build config.
3. Build locally.
4. Run and validate locally.
5. Update GitHub Actions publish matrix.
6. Push to `master`.
7. Confirm Docker Hub tag and smoke test.

---

## 1) Decide What You Are Releasing

Before changing files, agree these values:

- GeoServer version (for example `2.28.4`)
- Docker Hub tag name (for example `2.28.4-arm64`)
- Target platform (`linux/amd64` or `linux/arm64/v8`)
- GDAL enabled or not (`gdal_native: true|false`)
- Tomcat base image

Quick rule:

- If this is a routine GeoServer patch upgrade, keep Tomcat/GDAL unchanged unless there is a known requirement.

---

## 2) Update Build Configuration

Edit [build/build-config.yml](build/build-config.yml).

Typical keys to review:

- `gs_version`
- `tomcat_image`
- `gdal_version`
- `gdal_native`
- `tomcat_extras`
- `build_platform`
- `plugins`
- `community_plugins`

Checklist:

- Plugin names are correct for the chosen GeoServer version.
- `build_platform` matches what you want to test locally first.
- ARM64 comments are updated if you are preparing an ARM release.

---

## 3) Build Locally First (Required)

### Windows

From [build](build):

```powershell
.\build.bat
```

### Linux/macOS

From [build](build):

```bash
chmod +x build.sh
./build.sh
```

Expected behavior:

- Existing plugin ZIP files are skipped.
- Missing ZIP files are downloaded.
- Image is built locally only (no push).

---

## 4) Run and Validate Locally

### Windows example using repo-local data dir

```powershell
docker rm -f geoserver_local 2>$null
docker run --name geoserver_local -p 8085:8080 -d -v "C:\data\DATA_TEAM\geoserver_upgrade\generation_of_images\GeoServer-Docker\build\resources\data_dir:/opt/geoserver/data_dir" -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_8085.log" thinkwhere/geoserver:2.28.4
```

Validation checklist:

- Container is up (`docker ps`).
- No startup failures in logs (`docker logs -f geoserver_local`).
- GeoServer UI opens at `http://localhost:8085/geoserver`.
- Expected plugins are visible/usable.
- If GDAL is enabled, expected raster workflows function.

---

## 5) Prepare CI Publish Settings

Edit [.github/workflows/main.yml](.github/workflows/main.yml).

In the matrix entry, update:

- `tag`
- `gs-version`
- `tomcat-image`
- `gdal-version`
- `gdal-native`
- `tomcat-extras`
- `platform`

Why this matters:

- CI publish does not read your local shell variables.
- CI pushes exactly what the workflow matrix says.

---

## 6) Commit and Push

Commit the release changes, then push to `master`.

Typical files changed for a release:

- [build/build-config.yml](build/build-config.yml)
- [.github/workflows/main.yml](.github/workflows/main.yml)
- Optional: docs updates

---

## 7) What GitHub Actions Does

On push to `master`, workflow [main.yml](.github/workflows/main.yml) will:

1. Checkout repository.
2. Login to Docker Hub using secrets.
3. Setup QEMU/Buildx.
4. Run [build/download.sh](build/download.sh) to fetch plugin ZIPs.
5. Build using `build/Dockerfile` with matrix build args.
6. Push image to Docker Hub with the matrix tag.

---

## 8) Post-Publish Verification

After CI is green:

1. Confirm tag exists on Docker Hub (`thinkwhere/geoserver:<tag>`).
2. Pull that exact tag on a clean machine.
3. Run a quick smoke test container.
4. Confirm startup and key plugin behavior.

---

## Troubleshooting Notes

### Build warning about `ARG` in `FROM`

If Docker warns about invalid default arg in `FROM`, but build uses valid args from scripts/workflow, it is usually non-blocking.

### Docker daemon connection errors on Windows

If you see `dockerDesktopLinuxEngine` connection errors, ensure Docker Desktop is running and Linux containers are active.

### Plugin download mismatch

If plugin ZIP names are wrong for a version, update plugin lists in [build/build-config.yml](build/build-config.yml) and rerun local build.

---

## Quick Release Checklist

- [ ] Updated [build/build-config.yml](build/build-config.yml)
- [ ] Local build passed
- [ ] Local run passed
- [ ] Updated matrix in [.github/workflows/main.yml](.github/workflows/main.yml)
- [ ] Pushed to `master`
- [ ] GitHub Actions passed
- [ ] Docker Hub tag verified
- [ ] Smoke test on published tag passed
