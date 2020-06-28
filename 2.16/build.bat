@Echo off

SET GS_VERSION=2.16.3

rem Create plugins folder if does not exist
if not exist .\resources\NUL mkdir .\resources
if not exist .\resources\plugins\NUL mkdir .\resources\plugins

SET plugins=control-flow,inspire,monitor,css,ysld,sldservice
 
rem Add in selected plugins.  Comment out or modify as required
rem works for windows 10 powershell

for %%f in (%plugins%) do (
	if not exist resources\plugins\geoserver-%%f-plugin.zip powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://sourceforge.net/projects/geoserver/files/GeoServer/%GS_VERSION%/extensions/geoserver-%GS_VERSION%-%%f-plugin.zip/download -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
	@ECHO geoserver-%%f-plugin downloaded.
)
rem https://downloads.sourceforge.net/project/geoserver/GeoServer/2.16.3/extensions/geoserver-2.16.3-inspire-plugin.zip?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fgeoserver%2Ffiles%2FGeoServer%2F2.16.3%2Fextensions%2Fgeoserver-2.16.3-inspire-plugin.zip%2Fdownload&ts=1593376342
rem https://sourceforge.net/projects/geoserver/files/GeoServer/${GS_VERSION}/extensions/${i}/download

rem build options include:
rem    TOMCAT_EXTRAS  [true | false]
rem    DISABLE_GWC    [true | false]  - default false; no longer recommended since 2.9
rem    GDAL_NATIVE    [true | false]  - default false; build with GDAL support

docker build --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver:%GS_VERSION% .
