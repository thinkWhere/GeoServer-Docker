@Echo off

SET "CONFIG_FILE=build-config.yml"

if not exist "%CONFIG_FILE%" (
	echo Config file not found: %CONFIG_FILE%
	exit /b 1
)

for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"gs_version:" "%CONFIG_FILE%"') do set "GS_VERSION=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"tomcat_image:" "%CONFIG_FILE%"') do set "TOMCAT_IMAGE=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"gdal_version:" "%CONFIG_FILE%"') do set "GDAL_VERSION=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"gdal_native:" "%CONFIG_FILE%"') do set "GDAL_NATIVE=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"tomcat_extras:" "%CONFIG_FILE%"') do set "TOMCAT_EXTRAS=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"build_platform:" "%CONFIG_FILE%"') do set "BUILD_PLATFORM=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"plugins:" "%CONFIG_FILE%"') do set "plugins=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /b /c:"community_plugins:" "%CONFIG_FILE%"') do set "community_plugins=%%B"

for /f "tokens=* delims= " %%A in ("%GS_VERSION%") do set "GS_VERSION=%%A"
for /f "tokens=* delims= " %%A in ("%TOMCAT_IMAGE%") do set "TOMCAT_IMAGE=%%A"
for /f "tokens=* delims= " %%A in ("%GDAL_VERSION%") do set "GDAL_VERSION=%%A"
for /f "tokens=* delims= " %%A in ("%GDAL_NATIVE%") do set "GDAL_NATIVE=%%A"
for /f "tokens=* delims= " %%A in ("%TOMCAT_EXTRAS%") do set "TOMCAT_EXTRAS=%%A"
for /f "tokens=* delims= " %%A in ("%BUILD_PLATFORM%") do set "BUILD_PLATFORM=%%A"
for /f "tokens=* delims= " %%A in ("%plugins%") do set "plugins=%%A"
for /f "tokens=* delims= " %%A in ("%community_plugins%") do set "community_plugins=%%A"

set "GS_VERSION=%GS_VERSION:\"=%"
set "TOMCAT_IMAGE=%TOMCAT_IMAGE:\"=%"
set "GDAL_VERSION=%GDAL_VERSION:\"=%"
set "GDAL_NATIVE=%GDAL_NATIVE:\"=%"
set "TOMCAT_EXTRAS=%TOMCAT_EXTRAS:\"=%"
set "BUILD_PLATFORM=%BUILD_PLATFORM:\"=%"
set "plugins=%plugins:\"=%"
set "community_plugins=%community_plugins:\"=%"

for /f "tokens=1,2 delims=." %%A in ("%GS_VERSION%") do set "BUILD_GS_VERSION=%%A.%%B"

set "plugins=%plugins:,= %"
set "community_plugins=%community_plugins:,= %"

rem Create plugins folder if does not exist
if not exist .\resources\NUL mkdir .\resources
if not exist .\resources\plugins\NUL mkdir .\resources\plugins

rem Download plugins from configuration
rem works for windows 10 powershell

for %%f in (%plugins%) do (
	if exist resources\plugins\geoserver-%%f-plugin.zip (
		@ECHO Skipping existing plugin: geoserver-%%f-plugin.zip
	) else (
		powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://sourceforge.net/projects/geoserver/files/GeoServer/%GS_VERSION%/extensions/geoserver-%GS_VERSION%-%%f-plugin.zip/download -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
		@ECHO geoserver-%%f-plugin downloaded.
	)
)

rem Community plugins are not available from sourgeforge
rem therefore source from https://build.geoserver.org/

for %%f in (%community_plugins%) do (
	if exist resources\plugins\geoserver-%%f-plugin.zip (
		@ECHO Skipping existing community plugin: geoserver-%%f-plugin.zip
	) else (
		powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://build.geoserver.org/geoserver/%BUILD_GS_VERSION%.x/community-latest/geoserver-%BUILD_GS_VERSION%-SNAPSHOT-%%f-plugin.zip -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
		@ECHO geoserver-%%f-plugin downloaded.
	)
)


rem Build options include:
rem    TOMCAT_EXTRAS  [true | false]
rem    GDAL_NATIVE    [true | false]  - default true in Dockerfile, override here as needed
rem    GS_VERSION                     - specifies which version of geoserver is to be built

rem Local AMD64 build (no push)
docker build --platform %BUILD_PLATFORM% --build-arg GS_VERSION=%GS_VERSION% --build-arg TOMCAT_IMAGE=%TOMCAT_IMAGE% --build-arg GDAL_VERSION=%GDAL_VERSION% --build-arg TOMCAT_EXTRAS=%TOMCAT_EXTRAS% --build-arg GDAL_NATIVE=%GDAL_NATIVE% -t thinkwhere/geoserver:%GS_VERSION% .

rem ARM64 build example (uncomment if needed)
rem docker buildx build --build-arg GS_VERSION=%GS_VERSION% --build-arg TOMCAT_EXTRAS=false --build-arg GDAL_NATIVE=false --platform linux/arm64/v8 -t thinkwhere/geoserver:%GS_VERSION% --push .
