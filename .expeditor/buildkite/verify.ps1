echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

#
# Software Languages
#

# Install Ruby + Devkit
$ErrorActionPreference = 'Stop'

echo "Downloading Ruby + DevKit"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile('https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.6.4-1/rubyinstaller-devkit-2.6.4-1-x64.exe', 'c:\\rubyinstaller-devkit-2.6.4-1-x64.exe')

echo "Installing Ruby + DevKit"
Start-Process c:\rubyinstaller-devkit-2.6.4-1-x64.exe -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

echo "Cleaning up installation"
Remove-Item c:\rubyinstaller-devkit-2.6.4-1-x64.exe -Force
echo "Closing out the layer (this can take awhile)"

$Env:path +=";C:\ruby26\bin"

winrm quickconfig -q
ruby -v
bundle --version
bundle env

echo "--- bundle install"
bundle install --jobs=7 --retry=3 --without tools integration travis style omnibus_package aix bsd linux mac_os_x solaris

echo "+++ bundle exec rspec"
bundle exec rspec

exit $LASTEXITCODE