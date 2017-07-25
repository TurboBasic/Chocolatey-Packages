# you do not edit below this line! in fact you DO NOT edit below the line above this one.

$ErrorActionPreference = 'Stop'

$packageName = $env:ChocolateyPackageName
#$toolsDir    = "$(  Split-Path -parent $MyInvocation.MyCommand.Definition  )"
$url         = 'http://pspad.poradna.net/release/pspad462_setup.exe'


$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = "$(  Split-Path -Parent $MyInvocation.MyCommand.Definition  )"
  fileType       = 'exe'
  URL            = $url
  checksum       = '8DB4CB8311574F41B0C90908F4B96189'
  checksumType   = 'md5'

  silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes = @(0)
#  file           = Get-Item $toolsDir\*.zip
  skipShims      = @('phpCB.exe', 'TiDy.exe')
  softwareName   = 'PSPad'
}

foreach ($file in $packageArgs.skipShims) {
  New-Item -Path $packageArgs.unzipLocation -Name "$file.ignore" -Type file -Force | 
      Out-Null
}

Install-ChocolateyPackage @packageArgs
rm $toolsDir\pspad*setup.exe -EA 0


