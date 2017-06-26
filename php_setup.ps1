<#
Script to download and install versions of PHP. The script accepts the following params
-version specified like 5.6 (or if you know the hotifx you can specify the full version e.g. 5.6.30)

Written by Steve Copestake
26-06-2017
v1.0
#>

Param(
    [Parameter(Position=0, Mandatory=$True, ValueFromPipeline=$True)]
    [string]$version
     )

#Finds the version of PHP from http://windows.php.net/download
#First lets look for a new release
$phpuri = "http://windows.php.net"

$r=iwr $phpuri/downloads/releases/ -UseBasicParsing  
$phplinks = ($r.Links |?{$_.href -match ".zip"}).href | where {$_ -match "php-$version" -and $_ -match "nts" -and $_ -notmatch "pack"}

if ($phplinks.Count -eq 0) {

                           #Look in the archive list just incase we've missed something
                           $r=iwr $phpuri/downloads/releases/archives/ -UseBasicParsing  
                           $phplinks = ($r.Links |?{$_.href -match ".zip"}).href | where {$_ -match "php-$version" -and $_ -match "nts" -and $_ -notmatch "pack"}
                           if ($phplinks.count -eq 0) {Write-Output "Unable to find any version of PHP matching $version"; exit}
                           
                           }

#Lets get the latest version
$tonatural = { [regex]::Replace($_, '(\d+)\.?(\d*)', { $args[0].Value.PadLeft(20) }) }



# Sort with helper and check the output is natural result
$phplatest = $phplinks | sort $ToNatural -Descending | select -First 1

#Select the version number we're going to install and save it for later
$installversion = ($phplatest -split '-')[1]

#If there's a x86 and x64 version, let's just pick the x64 one.
if ($phplinks.Count -gt 1) {
$phplatest = $phplinks | select-string "x64"
}

$phpurl = $phpuri+$phplatest

$title = "Install PHP"
$message = "Do you want to install this version of PHP $phpurl"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Install this version of PHP"

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Cancel. If you wanted to install an older version please try again and specify the exact version."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

if ($result -eq 0) {
                    Write-Output "Beginning Install"

                    Write-Output "Attempting to load PHP snapin"
                    if ( (Get-PSSnapin -Name PHPManagerSnapin -ErrorAction SilentlyContinue) -eq $null )
                    {
                                 Add-PsSnapin PHPManagerSnapin 
                    }

                    Write-Output "Downloading PHP"
                    Invoke-WebRequest -Uri $phpurl -OutFile C:\php-$version.zip -Verbose 

                    $testpath = Test-Path C:\php-$version.zip

                    if ($testpath -eq $false) {"PHP download failed"; break}

                    Write-Output "Expanding PHP zip"
                    Expand-Archive C:\php-$version.zip C:\php-$version -force
                        
                    
                    Write-Output "Creating the PHP installation directories"
                    $pathtox64 = "C:\Program Files\PHP\v$version"
                    $pathtox86 = "C:\Program Files (x86)\PHP\v$version"
                   
                    
                    if ($phplatest -match "x64") {
                    #We're doing a x64 bit install
                    $installdir = $pathtox64
                                                if ((test-path "$pathtox64") -eq $false) {
                                                                                        New-Item -ItemType directory -Path "$pathtox64"
                                                                                                          
                                                                                       }
                                                }
                    elseif ($phplatest -match "x86") {
                    #We're doing a x86 bit install
                    $installdir = $pathtox86
                                                if ((test-path "$pathtox86") -eq $false) {
                                                                                        New-Item -ItemType directory -path "$pathtox86"
                                                                                       }
                                                }
                    else {"Something went horribly wrong, $phplatest doesn't appear to be formatted correctly"; break}

                    
                    #Copy the files to the install directory                                                                           
                    Write-Output "Copying PHP to install directory"
                    copy-item -Path C:\php-$version\* -Destination $installdir -force -Verbose -Recurse


                    Write-Output "Configuring the PHP ini"
                    Copy-Item -Path "$installdir\php.ini-production" -Destination "$installdir\php.ini" -force -Verbose
                    $file = gc "$installdir\php.ini" | where {$_ -match "; extension_dir = `"ext`""}
                    $file -replace ";"

                    #Add the PHP version to the FastCGI settings in IIS
                    New-PHPVersion -ScriptProcessor "$installdir\php-cgi.exe"


                                      
                    #Assume that if there's no PHP string the path then it's a new installation
                    if ($envpath = $Env:path | where {$_ -notmatch "php"}) {

                    $env:Path += "$installdir"
                   
                    }
                    
                                             

                    #Check if the version we're installing is newer than the currently installed version
                    $currentinstall = (get-phpconfiguration).version
                    if ([System.Version]$installversion -gt [System.Version]$currentinstall) {
                     
                                 Write-Output "Modifying the system path"
                                 (($env:path | where {$_ -match "php"}))
                                  
                                  #Update the system path to include the latest version of PHP         
                                  $split = $env:path -split ";" | where {$_ -notmatch "php"}
                                  $newpath = $split -join ';'
                                  $env:Path = $newpath

                    }
                                                    

                   

                  
                   
             
                 }

if ($result -eq 1 ){exit}
