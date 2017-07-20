param($packageName)

write-host "Testing $packageName"

$chocPath = "c:\nuget"
$binFile = "c:\nuget\bin\$packageName.bat"

if(test-path $binFile) {
    Write-host "Removing $binFile"
    Remove-Item $binFile
}

[xml] $nuspec = (get-content "$packageName\$packageName.nuspec")

$version = $nuspec.package.metadata.version
$libPath = "c:\nuget\lib\$packageName.$version"
if(test-path $libPath) {
    Remove-Item -Recurse -Path $libPath
}

Write-Host "Creating new package file"

$localNugetRepository = ((Split-Path -parent $MyInvocation.MyCommand.Definition) | Split-Path -Parent | Join-Path -ChildPath 'MyNugetRepository')
if(!(test-path $localNugetRepository)) {
    new-item -Type directory -Path $localNugetRepository
}

.\chocolatey\tools\chocolateyInstall\NuGet.exe pack .\$packageName\$packageName.nuspec /outputdirectory $localNugetRepository

chocolatey test_install $packageName $localNugetRepository




