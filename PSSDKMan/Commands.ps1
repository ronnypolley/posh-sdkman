function psdk([string]$Command, [string]$Candidate, [string]$Version, [string]$InstallPath, [switch]$Verbose, [switch]$Force) {
    $ErrorActionPreference = 'Stop'
	$ProgressPreference = 'SilentlyContinue'
	if ($Verbose) { $VerbosePreference = 'Continue' }

    if ( !( Test-Path $Global:PSDK_DIR ) ) {
        Write-Warning "$Global:PSDK_DIR does not exists. Reinitialize posh-sdk"
        Initialize-Posh-SDK
    }

    $Script:PSDK_AVAILABLE = $true
    if ( !($Script:PSDK_FORCE_OFFLINE) -and $Command -ne 'offline' ) {
        Test-Available-Broadcast $Command

        if ( $Script:PSDK_AVAILABLE ) {
            if ( $Script:FIRST_RUN ) {
                Test-SDKMAN-API-Version
                Test-Posh-SDK-Version
                $Script:FIRST_RUN = $false
            }
            Write-New-Version-Broadcast
        }
    }

    Initialize-Candidate-Cache

    Write-Verbose "Command: $Command"

    if ($Command -eq '') {
        $Command = 'help'
    }

    try {
        switch -regex ($Command) {
            '^i(nstall)?$'    { Install-Candidate-Version $Candidate $Version $InstallPath }
            '^(uninstall|rm)$'{ Uninstall-Candidate-Version $Candidate $Version }
            '^(ls|list)$'     { Show-Candidate-Versions $Candidate }
            '^u(se)?$'        { Use-Candidate-Version $Candidate $Version }
            '^d(efault)?$'    { Set-Default-Version $Candidate $Version }
            '^c(urrent)?$'    { Show-Current-Version $Candidate }
            '^v(ersion)?$'    { Show-Posh-SDK-Version }
            '^b(roadcast)?$'  { Show-Broadcast-Message }
            '^h(elp)?$'       { Show-Help }
            '^offline$'       { Set-Offline-Mode $Candidate }
            '^selfupdate$'    { Invoke-Self-Update($Force) }
            '^flush$'         { Clear-Cache $Candidate }
            default           { Write-Warning "Invalid command: $Command. Check psdk help!" }
        }
    } catch {
        if ( $_.CategoryInfo.Category -eq 'OperationStopped') {
            Write-Warning $_.CategoryInfo.TargetName
        } else {
            throw
        }
    }
}

function Install-Candidate-Version($Candidate, $Version, $InstallPath) {
    Write-Verbose 'Perform Install-Candidate-Version'
    Test-Candidate-Present $Candidate

    $localInstallation = $false
    if ($Version -and $InstallPath) {
        #local installation
        try {
            $Version = Test-Candidate-Version-Available $Candidate $Version
        } catch {
            $localInstallation = $true
        }
		if ( !($localInstallation) ) {
			throw 'Stop! Local installation for $Candidate $Version not possible. It exists remote already.'
		}
    } else {
        $Version = Test-Candidate-Version-Available $Candidate $Version
    }

    if ( Test-Is-Candidate-Version-Locally-Available $Candidate $Version ) {
        throw "Stop! $Candidate $Version is already installed."
    }

    if ( $localInstallation ) {
        Install-Local-Version $Candidate $Version $InstallPath
    } else {
        Install-Remote-Version $Candidate $Version
    }

    $default = $false
    if ( !$Global:PSDK_AUTO_ANSWER ) {
        $default = (Read-Host -Prompt "Do you want $Candidate $Version to be set as default? (Y/n)") -match '(y|\A\z)'
    } else {
        $default = $true
    }

    if ( $default ) {
        Write-Output "Setting $Candidate $Version as default."
        Set-Linked-Candidate-Version $Candidate $Version
    }
}

function Uninstall-Candidate-Version($Candidate, $Version) {
    Write-Verbose 'Perform Uninstall-Candidate-Version'
    Test-Candidate-Present $Candidate
    Test-Version-Present $Version

    if ( !(Test-Is-Candidate-Version-Locally-Available $Candidate $Version) ) {
        throw "$Candidate $Version is not installed."
    }

    $current = Get-Current-Candidate-Version $Candidate

    if ( $current -eq $Version ) {
        Write-Output "Unselecting $Candidate $Version..."
        (Get-Item "$Global:PSDK_DIR\$Candidate\current").Delete()
    }

    Write-Output "Uninstalling $Candidate $Version..."
    Remove-Item -Recurse -Force "$Global:PSDK_DIR\$Candidate\$Version"
}

function Show-Candidate-Versions($Candidate) {
    Write-Verbose 'Perform List-Candidate-Version'
    Test-Candidate-Present $Candidate
    if ( Get-Online-Mode ) {
        Write-Version-List $Candidate
    } else {
        Write-Offline-Version-List $Candidate
    }
}

function Use-Candidate-Version($Candidate, $Version) {
    Write-Verbose 'Perform Use-Candidate-Version'
    $Version = Test-Candidate-Version-Available $Candidate $Version

    if ( $Version -eq (Get-Env-Candidate-Version $Candidate) ) {
        Write-Output "$Candidate $Version is used. Nothing changed."
    } else {
        Test-Candidate-Version-Locally-Available $Candidate $Version
        Set-Env-Candidate-Version $Candidate $Version
		Write-Output "Using $CANDIDATE version $Version in this shell."
    }
}

function Set-Default-Version($Candidate, $Version) {
    Write-Verbose 'Perform Set-Default-Version'
    $Version = Test-Candidate-Version-Available $Candidate $Version

    if ( $Version -eq (Get-Current-Candidate-Version $Candidate) ) {
        Write-Output "$Candidate $Version is already default. Nothing changed."
    } else {
        Test-Candidate-Version-Locally-Available $Candidate $Version
        Set-Linked-Candidate-Version $Candidate $Version
        Write-Output "Default $Candidate version set to $Version"
    }
}

function Show-Current-Version($Candidate) {
    Write-Verbose 'Perform Set-Current-Version'

    if ( !($Candidate) ) {
        Write-Output 'Using:'
        foreach ( $c in $Script:SDK_CANDIDATES ) {
            $v = Get-Env-Candidate-Version $c
            if ($v) {
                Write-Output "$c`: $v"
            }
        }
        return
    }

    Test-Candidate-Present $Candidate
    $Version = Get-Env-Candidate-Version $Candidate
    if ( $Version ) {
        Write-Output "Using $Candidate version $Version"
    } else {
        Write-Output "Not using any version of $Candidate"
    }
}

function Show-Posh-SDK-Version() {
    $poshSDKVersion = Get-Posh-SDK-Version
    $apiVersion = Get-SDKMAN-API-Version
    Write-Output "posh-sdk (POwer SHell Groovy enVironment Manager) $poshSDKVersion base on SDKMAN! $SDKMAN_BASE_VERSION and SDKMAN! API $apiVersion"
}

function Show-Broadcast-Message() {
    Write-Verbose 'Perform Show-Broadcast-Message'
    Get-Content $Script:PSDK_BROADCAST_PATH | Write-Output
}

function Set-Offline-Mode($Flag) {
    Write-Verbose 'Perform Set-Offline-Mode'
    switch ($Flag) {
        'enable'  { $Script:PSDK_FORCE_OFFLINE = $true; Write-Output 'Forced offline mode enabled.' }
        'disable' { $Script:PSDK_FORCE_OFFLINE = $false; $Script:PSDK_ONLINE = $true; Write-Output 'Online mode re-enabled!' }
        default   { throw "Stop! $Flag is not a valid offline offline mode." }
    }
}

function Clear-Cache($DataType) {
    Write-Verbose 'Perform Clear-Cache'
    switch ($DataType) {
        'candidates' {
                        if ( Test-Path $Script:PSDK_CANDIDATES_PATH ) {
                            Remove-Item $Script:PSDK_CANDIDATES_PATH
                            Write-Output 'Candidates have been flushed.'
                        } else {
                            Write-Warning 'No candidate list found so not flushed.'
                        }
                     }
        'broadcast'  {
                        if ( Test-Path $Script:PSDK_BROADCAST_PATH ) {
                            Remove-Item $Script:PSDK_BROADCAST_PATH
                            Write-Output 'Broadcast have been flushed.'
                        } else {
                            Write-Warning 'No prior broadcast found so not flushed.'
                        }
                     }
        'version'    {
                        if ( Test-Path $Script:PSDK_API_VERSION_PATH ) {
                            Remove-Item $Script:PSDK_API_VERSION_PATH
                            Write-Output 'Version Token have been flushed.'
                        } else {
                            Write-Warning 'No prior Remote Version found so not flushed.'
                        }
                     }
        'archives'   { Clear-Directory $Script:PSDK_ARCHIVES_PATH }
        'temp'       { Clear-Directory $Script:PSDK_TEMP_PATH }
        'tmp'        { Clear-Directory $Script:PSDK_TEMP_PATH }
        default      { throw 'Stop! Please specify what you want to flush.' }
    }
}

function Show-Help() {
    Write-Output @"
Usage: psdk <command> <candidate> [version]
    psdk offline <enable|disable>

    commands:
        install   or i    <candidate> [version]
        uninstall or rm   <candidate> <version>
        list      or ls   <candidate>
        use       or u    <candidate> [version]
        default   or d    <candidate> [version]
        current   or c    [candidate]
        version   or v
        broadcast or b
        help      or h
        offline           <enable|disable>
        selfupdate        [-Force]
        flush             <candidates|broadcast|archives|temp>
    candidate  :  $($Script:SDK_CANDIDATES -join ', ')

    version    :  where optional, defaults to latest stable if not provided

eg: psdk install groovy
"@
}
