@Echo off
SET "CONFIG_FILE=build-config.yml"
SET "GS_PORT=8085"
SET "DATA_DIR=%~dp0resources\data_dir"

if not exist "%CONFIG_FILE%" (
	echo Config file not found: %CONFIG_FILE%
	exit /b 1
)

for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"gs_version:" "%CONFIG_FILE%"') do set "GS_VERSION=%%B"
for /f "tokens=* delims= " %%A in ("%GS_VERSION%") do set "GS_VERSION=%%A"
set "GS_VERSION=%GS_VERSION:\"=%"

for %%I in ("%DATA_DIR%") do set "DATA_DIR=%%~fI"

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

docker rm -f geoserver_%GS_PORT% >NUL 2>&1
docker run --name=geoserver_%GS_PORT% -p %GS_PORT%:8080 -d -v "%DATA_DIR%:/opt/geoserver/data_dir" -e "GEOSERVER_LOG_LOCATION=/opt/geoserver/data_dir/logs/geoserver_%GS_PORT%.log" -t thinkwhere/geoserver:%GS_VERSION%
