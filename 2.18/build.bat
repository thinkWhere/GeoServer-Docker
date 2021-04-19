@Echo off

SET GS_VERSION=2.18.2

rem Create plugins folder if does not exist
if not exist .\resources\NUL mkdir .\resources
if not exist .\resources\plugins\NUL mkdir .\resources\plugins

SET plugins=control-flow,inspire,monitor,css,ysld,sldservice,web-resource
 
rem Download plugins from list above.  Modify list as required
rem works for windows 10 powershell

for %%f in (%plugins%) do (
	if not exist resources\plugins\geoserver-%%f-plugin.zip powershell.exe Invoke-WebRequest -OutFile resources/plugins/geoserver-%%f-plugin.zip -Uri https://sourceforge.net/projects/geoserver/files/GeoServer/%GS_VERSION%/extensions/geoserver-%GS_VERSION%-%%f-plugin.zip/download -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
	@ECHO geoserver-%%f-plugin downloaded.
)

rem Build options include:
rem    TOMCAT_EXTRAS  [true | false]
rem    GDAL_NATIVE    [true | false]  - default false; build with GDAL support
rem    GS_VERSION                     - specifies which version of geoserver is to be built

docker build --build-arg GS_VERSION=%GS_VERSION% --build-arg TOMCAT_EXTRAS=false -t thinkwhere/geoserver:%GS_VERSION% .
