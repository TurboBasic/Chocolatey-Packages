$url      = 'http://www.pspad.com/files/pspad/pspad462en.zip'
$checksum = 'b8a3041c47ea1ee5c9517024998626d4dab30339877f3741fda646780daa7c96'


# you do not edit below this line! in fact you DO NOT edit below the line above this one.

$installArgs = @{
  PackageName = 'PSPad.portable';
  Url = $url;
  Checksum = $checksum;
  ChecksumType ='sha256';
  UnzipLocation = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
}


$skipShims = @('phpCB.exe', 'TiDy.exe')
#generate .ignore files
foreach ($file in $skipShims) {
  
  New-Item -Path $installArgs.UnzipLocation -Name "$file.ignore" -type file -force | Out-Null
}


try {
  Install-ChocolateyZipPackage @installArgs
} 
catch {
  throw $_.Exception
}