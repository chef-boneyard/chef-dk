$ErrorActionPreference = 'Stop'

# The filename of the Ruby installer
$RubyFilename = "rubyinstaller-devkit-2.6.5-1-x64.exe"

# The sha256 of the Ruby installer (capitalized?)
$RubySHA256 = "BD2050496A149C7258ED4E2E44103756CA3A05C7328A939F0FDC97AE9616A96D"

# Where on disk to download Ruby to
$RubyPath = "$env:temp\$RubyFilename"

# Where to download Ruby from:
$RubyS3Path = "s3://public-cd-buildkite-cache/$RubyFilename"

Function DownloadRuby
{
  $RandDigits = Get-Random
  echo "Downloading Ruby + DevKit"

  aws s3 cp "$RubyS3Path" "$RubyPath.$RandDigits" | Out-Null # Out-Null is a hack to wait for the process to complete

  if ($LASTEXITCODE -ne 0) {
    echo "aws s3 download failed: $LASTEXITCODE"
    exit $LASTEXITCODE
  }

  $FileHash = (Get-FileHash "$RubyPath.$RandDigits" -Algorithm SHA256).Hash
  If ($FileHash -eq $RubySHA256) {
    echo "Downloaded SHA256 matches: $FileHash"
  } Else {
    echo "Downloaded file hash $FileHash does not match desired $RubySHA256"
    exit 1
  }

  # On a shared filesystem, sometimes a good file appears while we are downloading
  If (Test-Path $RubyPath) {
    $FileHash = (Get-FileHash "$RubyPath" -Algorithm SHA256).Hash
    If ($FileHash -eq $RubySHA256) {
      echo "A matching file appeared while downloading, using it."
      Remove-Item "$RubyPath.$RandDigits" -Force
      Return
    } Else {
      echo "Existing file does not match, bad hash: $FileHash"
      Remove-Item $RubyPath -Force
    }
  }

  echo "Moving file installer into place"
  Rename-Item -Path "$RubyPath.$RandDigits" -NewName $RubyFilename
}

Function InstallRuby
{
  If (Test-Path $RubyPath) {
    echo "$RubyPath already exists"

    $FileHash = (Get-FileHash "$RubyPath" -Algorithm SHA256).Hash
    If ($FileHash -eq $RubySHA256) {
      echo "Found matching Ruby + DevKit on disk"
    } Else {
      echo "SHA256 hash mismatch, re-downloading"
      DownloadRuby
    }
  } Else {
    echo "No Ruby found at $RubyPath, downloading"
    DownloadRuby
  }

  echo "Installing Ruby + DevKit"
  Start-Process $RubyPath -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

  echo "Cleaning up installation"
  Remove-Item $RubyPath -Force -ErrorAction SilentlyContinue
}

echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

echo "--- install ruby + devkit"

InstallRuby

# Set-Item -Path Env:Path -Value to include ruby26
$Env:Path+=";C:\ruby26\bin"

echo "--- configure winrm"

winrm quickconfig -q

echo "--- update bundler and rubygems"

ruby -v

$env:RUBYGEMS_VERSION=$(findstr rubygems omnibus_overrides.rb | %{ $_.split(" ")[3] })
$env:BUNDLER_VERSION=$(findstr bundler omnibus_overrides.rb | %{ $_.split(" ")[3] })

$env:RUBYGEMS_VERSION=($env:RUBYGEMS_VERSION -replace '"', "")
$env:BUNDLER_VERSION=($env:BUNDLER_VERSION -replace '"', "")

echo $env:RUBYGEMS_VERSION
echo $env:BUNDLER_VERSION

gem update --system $env:RUBYGEMS_VERSION
gem --version
gem install bundler -v $env:BUNDLER_VERSION --force --no-document --quiet
bundle --version

echo "--- bundle install"
bundle install --jobs=7 --retry=3 --without tools integration travis style omnibus_package aix bsd linux mac_os_x solaris

echo "+++ bundle exec rspec"
bundle exec rspec

exit $LASTEXITCODE
