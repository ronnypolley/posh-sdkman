function Write-Offline-Broadcast() {
    Write-Output @"
==== BROADCAST =================================================================

OFFLINE MODE ENABLED! Some functionality is now disabled.

================================================================================
"@
}

function Write-Online-Broadcast() {
    Write-Output @"
==== BROADCAST =================================================================

ONLINE MODE RE-ENABLED! All functionality now restored.

================================================================================

"@
}

function Write-New-Version-Broadcast() {
    if ( $Script:PSDK_API_NEW_VERSION -or $Script:PSDK_NEW_VERSION ) {
Write-Output @"
==== UPDATE AVAILABLE ==========================================================

A new version is available. Please consider to execute:

    sdk selfupdate

================================================================================
"@
    }
}

function Test-SDKMAN-API-Version() {
    Write-Verbose 'Checking PSDK-Api version'
    try {
        $apiVersion = Get-SDKMAN-API-Version
        $sdkmanRemoteVersion = Invoke-API-Call "broker/download/sdkman/version/stable"

        if ( $sdkmanRemoteVersion -gt $apiVersion) {
            if ( $Global:PSDK_AUTO_SELFUPDATE ) {
                Invoke-Self-Update
            } else {
                $Script:PSDK_API_NEW_VERSION = $true
            }
        }
    } catch {
        $Script:PSDK_AVAILABLE = $false
    }
}

function Test-Posh-SDK-Version() {
    Write-Verbose 'Checking posh-sdk version'
    if ( Test-New-Posh-SDK-Version-Available ) {
        if ( $Global:PSDK_AUTO_SELFUPDATE ) {
            Invoke-Self-Update
        } else {
            $Script:PSDK_NEW_VERSION = $true
        }
    }
}

function Get-Posh-SDK-Version() {
    return Get-Content $Script:PSDK_VERSION_PATH
}

function Test-New-Posh-SDK-Version-Available() {
    try {
        $localVersion = (Get-Posh-SDK-Version).Trim()
        $currentVersion = (Invoke-RestMethod $Script:PSDK_VERSION_SERVICE).Trim()

        Write-Verbose "posh-sdk version check $currentVersion > $localVersion = $($currentVersion -gt $localVersion)"

        return ( $currentVersion -gt $localVersion )
    } catch {
        return $false
    }
}

function Get-SDKMAN-API-Version() {
	if ( !(Test-Path $Script:PSDK_API_VERSION_PATH) ) {
		return $null
	}
    return Get-Content $Script:PSDK_API_VERSION_PATH
}

function Test-Available-Broadcast($Command) {
    $version = Get-SDKMAN-API-Version
    if ( !( $version ) ) {
        return
    }

    $liveBroadcast = Invoke-Broadcast-API-Call

	Write-Verbose "Online-Mode: $Script:PSDK_AVAILABLE"

	if ( $Script:PSDK_ONLINE -and !($Script:PSDK_AVAILABLE) ) {
		Write-Offline-Broadcast
	} elseif ( !($Script:PSDK_ONLINE) -and $Script:PSDK_AVAILABLE ) {
		Write-Online-Broadcast
	}
	$Script:PSDK_ONLINE = $Script:PSDK_AVAILABLE

	if ( $liveBroadcast ) {
		Resolve-Broadcast $Command $liveBroadcast
	}
}

function Invoke-Broadcast-API-Call {
    try {
        $target = "$Script:PSDK_BROADCAST_SERVICE/broadcast/latest"
        Write-Verbose "Broadcast API call to: $target"
        return Invoke-RestMethod $target
    } catch {
        Write-Verbose "Could not reached broadcast API"
        $Script:PSDK_AVAILABLE = $false
        return $null
    }
}

function Invoke-Self-Update($Force) {
    Write-Verbose 'Perform Invoke-Self-Update'
    Write-Output 'Update list of available candidates...'
    Update-Candidates-Cache
    $Script:PSDK_API_NEW_VERSION = $false
    if ( $Force ) {
        Invoke-Posh-SDK-Update
    } else {
        if ( Test-New-Posh-SDK-Version-Available ) {
            Invoke-Posh-SDK-Update
        }
    }
    $Script:PSDK_NEW_VERSION = $false
}

function Invoke-Posh-SDK-Update {
    Write-Output 'Update posh-sdk...'
    . "$psScriptRoot\GetPoshSDK.ps1"
}

function Test-Candidate-Present($Candidate) {
    if ( !($Candidate) ) {
        throw 'No candidate provided.'
    }

    if ( !($Script:SDK_CANDIDATES -contains $Candidate) ) {
        throw "Stop! $Candidate is no valid candidate!"
    }
}

function Test-Version-Present($Version) {
    if ( !($Version)) {
        throw 'No version provided.'
    }
}

function Test-Candidate-Version-Available($Candidate, $Version) {
    Test-Candidate-Present $Candidate

    $UseDefault = $false
    if ( !($Version) ) {
        Write-Verbose 'No version provided. Fallback to default version!'
        $UseDefault = $true
    }

    # Check locally
    elseif ( Test-Is-Candidate-Version-Locally-Available $Candidate $Version ) {
        return $Version
    }

    # Check if offline
    if ( ! (Get-Online-Mode) ) {
        if ( $UseDefault ) {
            $Version = Get-Current-Candidate-Version $Candidate
            if ( $Version ) {
                return $Version
            } else {
                throw "Stop! No local default version for $Candidate and in offline mode."
            }
        }

        throw "Stop! $Candidate $Version is not available in offline mode."
    }

    if ( $UseDefault ) {
        Write-Verbose 'Try to get default version from remote'
        return Invoke-API-Call "candidates/default/$Candidate"
    }

    $VersionAvailable = Invoke-API-Call "candidates/validate/$Candidate/$Version/cygwin"

    if ( $VersionAvailable -eq 'valid' ) {
        return $Version
    } else {
        throw "Stop! $Version is not a valid $Candidate version."
    }
}

function Get-Current-Candidate-Version($Candidate) {
    $currentLink = "$Global:PSDK_DIR\$Candidate\current"

    $targetItem = Get-Junction-Target $currentLink

    if ($targetItem) {
        return $targetItem.Name
    }

    return $null
}

function Get-Junction-Target($linkPath) {
    if ( Test-Path $linkPath ) {
        try {
            $linkItem = Get-Item $linkPath

            if (Get-Member -InputObject $linkItem -Name "ReparsePoint") {
                return (Get-Item $linkItem.ReparsePoint.Target)
            }

            if (Get-Member -InputObject $linkItem -Name "Target") {
                return (Get-Item $linkItem.Target)
            }
        } catch {
            return $null
        }
    }

    return $null
}

function Get-Env-Candidate-Version($Candidate) {
    $envLink = [System.Environment]::GetEnvironmentVariable(([string]$Candidate).ToUpper() + "_HOME")

    if ( $envLink -match '(.*)current$' ) {
        Get-Current-Candidate-Version $Candidate
    } else {
        return (Get-Item $envLink).Name
    }
}

function Test-Candidate-Version-Locally-Available($Candidate, $Version) {
    if ( !(Test-Is-Candidate-Version-Locally-Available $Candidate $Version) ) {
        throw "Stop! $Candidate $Version is not installed."
    }
}

function Test-Is-Candidate-Version-Locally-Available($Candidate, $Version) {
    if ( $Version ) {
        return Test-Path "$Global:PSDK_DIR\$Candidate\$Version"
    } else {
        return $false
    }
}

function Get-Installed-Candidate-Version-List($Candidate) {
    return Get-ChildItem "$Global:PSDK_DIR\$Candidate" | ?{ $_.PSIsContainer -and $_.Name -ne 'current' } | ForEach-Object { $_.Name }
}

function Get-Online-Candidate-Version-List($Candidate) {
    $versions = Select-String "\d+(\.\w*\d*)*(-(\w|\d)*)?" -InputObject (Get-Version-List $Candidate) -AllMatches
    $resultVersions =  $versions.Matches.Captures |  ForEach-Object { Write-Output $_.Value }
    return $resultVersions
}

function Set-Env-Candidate-Version($Candidate, $Version) {
    $candidateEnv = ([string]$candidate).ToUpper() + "_HOME"
    $candidateDir = "$Global:PSDK_DIR\$candidate"
    $candidateHome = "$candidateDir\$Version"
    $candidateBin = "$candidateHome\bin"

    if ( !([Environment]::GetEnvironmentVariable($candidateEnv) -eq $candidateHome) ) {
        [Environment]::SetEnvironmentVariable($candidateEnv, $candidateHome)
    }

    $env:PATH = "$candidateBin;$env:PATH"
}

function Set-Linked-Candidate-Version($Candidate, $Version) {
    $Link = "$Global:PSDK_DIR\$Candidate\current"
    $Target = "$Global:PSDK_DIR\$Candidate\$Version"
    Set-Junction-Via-Mklink $Link $Target
}

function Set-Junction-Via-Mklink($Link, $Target) {
    if ( Test-Path $Link ) {
        (Get-Item $Link).Delete()
    }
    New-Item -Path $Link -ItemType SymbolicLink -Value $Target | Out-Null
}

function Get-Online-Mode() {
    return $Script:PSDK_AVAILABLE -and ! ($Script:PSDK_FORCE_OFFLINE)
}

function Test-Online-Mode() {
    if ( ! (Get-Online-Mode) ) {
        throw 'This command is not available in offline mode.'
    }
}

function Invoke-API-Call([string]$Path, [string]$FileTarget, [switch]$IgnoreFailure) {
    try {
        $target = "$Script:PSDK_SERVICE/$Path"

        if ( $FileTarget ) {
            return Invoke-RestMethod $target -OutFile $FileTarget
        }

        return Invoke-RestMethod $target
    } catch {
        $Script:PSDK_AVAILABLE = $false
        if ( ! ($IgnoreFailure) ) {
            Test-Online-Mode
        } else {
			return $null
		}
    }
}

function Clear-Directory($Path) {
    $dirStats = Get-ChildItem $Path -Recurse | Measure-Object -property length -sum
    Remove-Item -Force -Recurse $Path
    $count = $dirStats.Count
    $size = $dirStats.Sum/(1024*1024)
    Write-Output "$count archive(s) flushed, freeing $size MB"
}

function Resolve-Broadcast($Command, $Broadcast) {
    $oldBroadcast = $null
    if (Test-Path $Script:PSDK_BROADCAST_PATH) {
        $oldBroadcast = (Get-Content $Script:PSDK_BROADCAST_PATH) -join "`n"
        Write-Verbose 'Old broadcast message loaded'
    }

    if ($oldBroadcast -ne $Broadcast -and !($Command -match 'b(roadcast)?') -and $Command -ne 'selfupdate' -and $Command -ne 'flush' ) {
        Write-Verbose 'Showing the new broadcast message'
        Set-Content $Script:PSDK_BROADCAST_PATH $Broadcast
        Write-Output $Broadcast
    }
}

function Initialize-Candidate-Cache() {
    if ( !(Test-Path $Script:PSDK_CANDIDATES_PATH) ) {
        throw 'Can not retrieve list of candidates'
    }

    $Script:SDK_CANDIDATES = (Get-Content $Script:PSDK_CANDIDATES_PATH).Split(',')
    Write-Verbose "Available candidates: $Script:SDK_CANDIDATES"
}

function Update-Candidates-Cache() {
    Write-Verbose 'Update candidates-cache from PSDK-Api'
    Test-Online-Mode
    Invoke-Api-Call 'broker/download/sdkman/version/stable' $Script:PSDK_API_VERSION_PATH
    Invoke-API-Call 'candidates/all' $Script:PSDK_CANDIDATES_PATH
}

function Write-Offline-Version-List($Candidate) {
    Write-Verbose 'Get version list from directory'

    Write-Output '------------------------------------------------------------'
    Write-Output "Offline Mode: only showing installed ${Candidate} versions"
    Write-Output '------------------------------------------------------------'
    Write-Output ''

    $current = Get-Current-Candidate-Version $Candidate
    $versions = Get-Installed-Candidate-Version-List $Candidate

    if ($versions) {
        foreach ($version in $versions) {
            if ($version -eq $current) {
                Write-Output " > $version"
            } else {
                Write-Output " * $version"
            }
        }
    } else {
        Write-Output '    None installed!'
    }

    Write-Output '------------------------------------------------------------'
	Write-Output '* - installed                                               '
	Write-Output '> - currently in use                                        '
	Write-Output '------------------------------------------------------------'
}

function Write-Version-List($Candidate) {
    Write-Verbose 'Write version list from API to CLI'
    Write-Output (Get-Version-List $Candidate)
}

function Get-Version-List($Candidate) {
    Write-Verbose 'Get version list from API'

    $current = Get-Current-Candidate-Version $Candidate
    $versions = (Get-Installed-Candidate-Version-List $Candidate) -join ','
    return Invoke-API-Call "candidates/$Candidate/cygwin/versions/list?current=$current&installed=$versions"
}

function Install-Local-Version($Candidate, $Version, $LocalPath) {
    $dir = Get-Item $LocalPath

    if ( !(Test-Path $dir -PathType Container) ) {
        throw "Local installation path $LocalPath is no directory"
    }

    Write-Output "Linking $Candidate $Version to $LocalPath"
    $link = "$Global:PSDK_DIR\$Candidate\$Version"
    Set-Junction-Via-Mklink $link $LocalPath
    Write-Output "Done installing!"
}

function Install-Remote-Version($Candidate, $Version) {

    if ( !(Test-Path $Script:PSDK_ARCHIVES_PATH) ) {
        New-Item -ItemType Directory $Script:PSDK_ARCHIVES_PATH | Out-Null
    }

    $archive = "$Script:PSDK_ARCHIVES_PATH\$Candidate-$Version.zip"
    if ( Test-Path $archive ) {
        Write-Output "Found a previously downloaded $Candidate $Version archive. Not downloading it again..."
    } else {
		Test-Online-Mode
        Write-Output "`nDownloading: $Candidate $Version`n"
        Get-File-From-Url "$Script:PSDK_SERVICE/broker/download/$Candidate/$Version`/cygwin" $archive $Candidate $Version
    }

    Write-Output "Installing: $Candidate $Version"

    # create temp dir if necessary
    if ( !(Test-Path $Script:PSDK_TEMP_PATH) ) {
        New-Item -ItemType Directory $Script:PSDK_TEMP_PATH | Out-Null
    } else {
        # clean existing temp dir
        Remove-Item "$Script:PSDK_TEMP_PATH\*.*" -Recurse -Force
    }

    # unzip downloaded archive
    Expand-Archive -Path $archive -DestinationPath $Script:PSDK_TEMP_PATH -Force

	# check if unzip successfully
	if ( ((Get-ChildItem -Directory $Script:PSDK_TEMP_PATH).count -ne 1) ) {
		throw "Could not unzip the archive of $Candidate $Version. Please delete archive from $Script:PSDK_ARCHIVES_PATH (or delete all with 'sdk flush archives'"
	}

    # needed to create the folder ahead. Else the copy process failed on the first try
    New-Item -ItemType Directory "$Global:PSDK_DIR\$Candidate\$Version" | Out-Null
    # move to target location
    # Move was replaced by copy and remove because of random access denied errors
    # when Unzip was done by via -com shell.application
    # Move-Item "$Script:PSDK_TEMP_PATH\*-$Version" "$Global:PSDK_DIR\$Candidate\$Version"
    Copy-Item -Path "$Script:PSDK_TEMP_PATH\$((Get-ChildItem -Directory $Script:PSDK_TEMP_PATH).name)\*" -Destination "$Global:PSDK_DIR\$Candidate\$Version" -Recurse
    Remove-Item "$Script:PSDK_TEMP_PATH\*.*" -Recurse -Force
    Write-Output "Done installing!"
}

function Get-File-From-Url($Url, $TargetFile, $Candidate, $Version) {
	<#
		Adepted from http://blogs.msdn.com/b/jasonn/archive/2008/06/13/downloading-files-from-the-internet-in-powershell-with-progress.aspx
	#>
    Write-Verbose "Try to download $Url with HttpWebRequest"
    $tempProgressPreference = $ProgressPreference
    $ProgressPreference = 'Continue'
	$uri = New-Object "System.Uri" $Url
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000)
    $response = $request.GetResponse()
	$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
	$responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
	$buffer = new-object byte[] 1000KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
	while ($count -gt 0)
    {
        if ($totalLength -lt 0) {
            $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
        }
        $currentPercentage = ([System.Math]::Floor(($downloadedBytes/1024)* 100/ $totalLength) )
        Write-Progress -Activity "Download $Candidate $Version" -Status "Downloaded $([System.Math]::Ceiling($downloadedBytes/1024))kB of $([System.Math]::Ceiling($totalLength))kB ($currentPercentage %)" -PercentComplete $currentPercentage
        $targetStream.Write($buffer, 0, $count)
        $count = $responseStream.Read($buffer,0,$buffer.length)
        $downloadedBytes = $downloadedBytes + $count
    }
    Write-Progress -Activity "Download $Candidate $Version" -Completed
    $targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
    Write-Output ''
    $ProgressPreference = $tempProgressPreference
}
