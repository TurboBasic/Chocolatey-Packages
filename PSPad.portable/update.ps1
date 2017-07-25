Import-Module au
. $PSScriptRoot\..\_scripts\all.ps1

#region function & alias declarations

  Function Replace-String { 
      [CMDLETBINDING()]
      PARAM(
          [PARAMETER( Mandatory, Position=0 )]
          [String] $from,
          
          [PARAMETER( Mandatory, Position=1 )]
          [String] $to,
          
          [PARAMETER( Position=2, ValueFromPipeline, ValueFromPipelineByPropertyName )]
          [String] $InputObject
      )
      
      $input | ForEach{ $_.replace($from, $to) }
  }
  
  New-Alias rs Replace-String -Scope Script

  Function Merge-Hashtables {
    $Result = @{}
    ($Input + $Args) | 
        Where   { ($_.Keys -ne $null) -and ($_.Values -ne $null) -and ($_.GetEnumerator -ne $null) } | 
        ForEach { $_.GetEnumerator() } | 
        ForEach { $Result[$_.Key] = $_.Value } 
    $Result
    Write-Verbose (ConvertTo-Json $Result -compress)
  }

#endregion


Function global:au_SearchReplace {

   @{
        '.\tools\chocolateyInstall.ps1' = @{
            "(?i)(^[$]*url\s*=\s*)('.*')"           = "`$1'$($Latest.URL32)'"
            "(?i)(^\s*checksum\s*=\s*)('.*')"       = "`$1'$($Latest.Checksum32)'"
            "(?i)(^\s*checksumType\s*=\s*)('.*')"   = "`$1'$($Latest.ChecksumType32)'"
        }
    }

}


Function global:au_AfterUpdate  { Set-DescriptionFromReadme -SkipFirst 2 }


Function global:au_GetLatest {
    $releasesUrl = 'http://www.pspad.com/en/download.php'

    $downloadPage = Invoke-WebRequest -Uri $releasesUrl
    $result = $null
    
    
    #region find product version
 
        $versionPattern = &{
  
            # regex: \d+\.\d+\.\d+
            $__version = "DIGITS.DIGITS.DIGITS"|  rs 'DIGITS'  "\d+"|  rs '.'  "\." 

            # regex: \(\d+\)                            
            $__build = "(DIGITS)"|  rs 'DIGITS'  "\d+"|  rs '('  "\("|  rs ')'  "\)"

            # regex: PSPad\s+-\s+current\s+version\s+(\d+\.\d+\.\d+)\s+\(\d+\)
            'PSPad - current version (VERSION) BUILD'| 
                rs 'VERSION' $__version|
                rs 'BUILD'   $__build|
                rs ' '       '\s+'
        }    
        #  PSPad\s+-\s+current\s+version\s+(\d+\.\d+\.\d+)\s+\(\d+\)
        #  $1 -> $Version;   $2 -> $Build

        $version=$null
        $foundItems = $downloadPage.ParsedHtml.getElementsByTagName('h2') |
            Where innerHTML -match $versionPattern |
            ForEach {  
              $version = $Matches[1]
              $Matches[0]
            }

        if(IsNull $foundItems) { Throw 'Version pattern not found' }
  
        if($foundItems.GetType() -ne [string]) {
          Write-Warning "Header selection pattern '$versionPattern' matches non-unique fragment"
          Write-Verbose ($foundItems -join "`n")
        }

        $versionShort = $version -replace '\.'
        $fileNameZip = "pspad${versionShort}en.zip"
        $result = Merge-Hashtables $result @{
            VersionShort = $versionShort
            Version      = $version
            FilenameZip  = $fileNameZip
        }
        Write-Verbose (ConvertTo-Json $result -compress)

    #endregion
    
    
    #region find download link

        # 'https?://pspad\.poradna\.net/release/(pspad${versionShort}_setup\.exe)$'    $1 -> $filenameExe
        $installExePattern = "https?://pspad.poradna.net/release/(pspad{DIGITS}_setup.exe)$"| 
                                rs '.'        '\.'| 
                                rs '{DIGITS}' $versionShort

        # 'https?://www\.pspad\.com/files/pspad/(pspad${versionShort}en\.zip)$'        $1 -> $filenameZip
        $installZipPattern = "https?://www.pspad.com/files/pspad/(pspad{DIGITS}en.zip)$"| 
                                rs '.'        '\.'| 
                                rs '{DIGITS}' $versionShort
  
        $foundItems = $downloadPage.links | 
            Where href -match $installZipPattern | 
            ForEach { 
              $urlInstallZip = $Matches[0]   
              $Matches[0] 
            }

        if(IsNull $foundItems) { Throw 'Download link pattern not found' }

        if($foundItems.GetType() -ne [string]) {
          Write-Warning "Download selection pattern '$installZipPattern' is non-unique"
          Write-Verbose ($foundItems -join "`n")
        }
        
        $result = Merge-Hashtables $result @{ URL32zip = $urlInstallZip }

    #endregion
    
    
    #region find checksums

        $checksumPattern = &{
            # regex: [0-9A-Fa-f]{32}
            $__md5 =  '32 HEXDIGITS'| 
                      rs '32 HEXDIGITS' "HEXDIGITS{32}"| 
                      rs 'HEXDIGITS'    "[0-9A-Fa-f]"
      
            $__filename = '[-._0-9A-Za-z]+'
      
            # checksum block:
            #     8DB4CB8311574F41B0C90908F4B96189  pspad462_setup.exe
            #     7B9EB70EAB8D8A6D222FAA121FD0545C  pspad462en.zip   
            # regex: 
            #     ([0-9A-Fa-f]{32})\s+([-._0-9A-Za-z]+)\s+([0-9A-Fa-f]{32})\s+([-._0-9A-Za-z]+)
      
            '(?s)^\s*(MD5) (FILENAME) (MD5) (${filenameZip})\s*$'|
                rs 'MD5'       $__md5|
                rs 'FILENAME'  $__filename|
                rs ' '         "\s+"
        }   
        #  ([0-9A-Fa-f]{32})\s+([-.0-9A-Za-z]+)\s+([0-9A-Fa-f]{32})\s+(${filenameZip})
        #  $1 -> $checksum32exe;   $2 -> $FileNameExe;   $3 -> $checksum32zip

        # Expand ${filenameZip} and don't forget to escape dot in $filenameZip
        $checksumPattern = &{ 
          $filenameZip = $filenameZip.replace('.', '\.')
          $ExecutionContext.InvokeCommand.ExpandString($checksumPattern)
        }
        Write-Verbose $checksumPattern

        $foundItems = $downloadPage.AllElements | 
            Where tagName -eq 'CODE' |
            Where {  $_.innerText -match $checksumPattern  }|
            ForEach { 
              $Checksum32exe      = $Matches[1]
              $FileNameExe        = $Matches[2]
              $Checksum32zip      = $Matches[3]
              $Matches[0] 
            } 
        if(IsNull $foundItems) {
          Throw 'Checksum pattern not found'
        }
        if($foundItems.GetType() -ne [string]) {
          Write-Warning "Checksum selection pattern $checksumPattern matches non-unique fragment"
          Write-Verbose ($foundItems -join "`n")
        }            
        
    #endregion    

    $result = Merge-Hashtables $result @{
        Checksum32exe      = $Checksum32exe
        FileNameExe        = $FileNameExe
        Checksum32zip      = $Checksum32zip
        ChecksumType32     = 'md5'
    }
        
    @{
        Version =        $result.Version
        URL32 =          $result.URL32zip
        Checksum32 =     $result.Checksum32zip
        ChecksumType32 = $result.ChecksumType32
    }
 
}


Update  -ChecksumFor none
