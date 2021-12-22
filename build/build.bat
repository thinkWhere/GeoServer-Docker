@Echo off

SET GS_VERSION=2.18.3
SET BUILD_GS_VERSION=%GS_VERSION:~0,4%

rem Remove all the plugins so they will be refetched on version change.
rmdir /S /Q .\resources\plugins

rem Create plugins folder if does not exist
if not exist .\resources\NUL mkdir .\resources
if not exist .\resources\plugins\NUL mkdir .\resources\plugins

SET plugins=control-flow,inspire,monitor,css,ysld,web-resource,sldservice,pyramid,gdal,importer
 
rem Download plugins from list above.  Modify list as required
rem works for windows 10 powershell

for %%f in (%plugins%) do (
	if not exist resources\plugins\geoserver-%%f-plugin.zip powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://sourceforge.net/projects/geoserver/files/GeoServer/%GS_VERSION%/extensions/geoserver-%GS_VERSION%-%%f-plugin.zip/download -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
	@ECHO geoserver-%%f-plugin downloaded.
)

SET community_plugins=s3-geotiff,imagemosaic-jdbc,pgraster

rem Community plugins are not available from sourgeforge
rem therefore source from https://build.geoserver.org/

for %%f in (%community_plugins%) do (
	if not exist resources\plugins\geoserver-%%f-plugin.zip powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://build.geoserver.org/geoserver/%BUILD_GS_VERSION%.x/community-latest/geoserver-%BUILD_GS_VERSION%-SNAPSHOT-%%f-plugin.zip -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
	@ECHO geoserver-%%f-plugin downloaded.
)

rem Create timestamp to add to Docker image
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
For /f "tokens=1-3 delims=/:/ " %%a in ('time /t') do (set mytime=%%a%%b%%c)
set mytime=%mytime: =% 
set BUILD_TIMESTAMP=%mydate%T%mytime%

rem Build options include:
rem    TOMCAT_EXTRAS  [true | false]
rem    GDAL_NATIVE    [true | false]  - default false; build with GDAL support
rem    GS_VERSION                     - specifies which version of geoserver is to be built

docker build --build-arg GS_VERSION=%GS_VERSION% --build-arg TOMCAT_EXTRAS=false --build-arg GDAL_NATIVE=true -t stevetarter/geoserver:%GS_VERSION%-%BUILD_TIMESTAMP% .
