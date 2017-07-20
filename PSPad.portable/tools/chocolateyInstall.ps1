# you do not edit below this line! in fact you DO NOT edit below the line above this one.

$ErrorActionPreference = 'Stop'

$packageName =  $env:ChocolateyPackageName
$toolsDir =     "$(  Split-Path -parent $MyInvocation.MyCommand.Definition  )"
$url =          'http://www.pspad.com/files/pspad/pspad462en.zip'
$download_dir = "$Env:TEMP\chocolatey\$packageName\$Env:ChocolateyPackageVersion"

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = "$(  Split-Path -parent $MyInvocation.MyCommand.Definition  )"
  URL            = $url
  checksum       = '7B9EB70EAB8D8A6D222FAA121FD0545C'
  checksumType   = 'md5'

  fileType       = 'zip'
  file           = Get-Item $toolsDir\*.zip
  validExitCodes = @(0)
  softwareName   = 'PSPad portable'
}

$skipShims      = @('phpCB.exe', 'TiDy.exe')
foreach ($file in $skipShims) {
  New-Item -Path $toolsDir -Name "$file.ignore" -type file -force | Out-Null
}

Install-ChocolateyZipPackage @packageArgs

rm $toolsDir\pspad*.zip -ea 0

$packageName = $packageArgs.packageName
$installLocation = Get-AppInstallLocation "$packageName*"
if (!$installLocation)  { Write-Warning "Can't find $packageName install location"; return }
Write-Host "$packageName installed to '$installLocation'"

