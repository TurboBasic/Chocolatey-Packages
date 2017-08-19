# you do not edit below this line! in fact you DO NOT edit below the line above this one.

$ErrorActionPreference = 'Stop'

$packageName =      $ENV:ChocolateyPackageName
$toolsDir =         Split-Path -parent $MyInvocation.MyCommand.Definition
$url =              'http://www.pspad.com/files/pspad/pspad462en.zip'
$download_dir =     '{0}\chocolatey\{1}\{2}' -f 
                        $ENV:Temp, $packageName, $ENV:ChocolateyPackageVersion

$packageArgs = @{
  packageName =     $packageName
  softwareName =    'PSPad portable'
  
  URL =             $url
  checksumType =    'md5'
  checksum =        '7B9EB70EAB8D8A6D222FAA121FD0545C'
  
  fileType =        'zip'
  file =            Get-Item -path $toolsDir\*.zip
  unzipLocation =   $toolsDir

  validExitCodes =  @(0)
}

# prevent chocolatey from creating shims for supplementary executables
foreach ( $file in 'phpCB.exe', 'TiDy.exe' ) {
  New-Item -path $toolsDir -name "$file.ignore" -type File -force | Out-Null
}

Install-ChocolateyZipPackage @packageArgs

Remove-Item -path $toolsDir\pspad*.zip -errorAction SilentlyContinue
