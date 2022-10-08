#region Initialization
function Initialize-Posh-SDK() {
    Write-Verbose 'Init posh-sdk'

    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    # Check if $Global:PSDK_DIR is available, if not create it
    if ( !( Test-Path "$Global:PSDK_DIR\.meta" ) ) {
        New-Item -ItemType Directory "$Global:PSDK_DIR\.meta" | Out-Null
    }

    # Load candidates cache
    if ( ! (Test-Path $Script:PSDK_CANDIDATES_PATH) ) {
        Update-Candidates-Cache
    }

    Initialize-Candidate-Cache

    #Setup default paths
    Foreach ( $candidate in $Script:SDK_CANDIDATES ) {
		if ( !( Test-Path "$Global:PSDK_DIR\$candidate" ) ) {
			New-Item -ItemType Directory "$Global:PSDK_DIR\$candidate" | Out-Null
		}

        Set-Env-Candidate-Version $candidate 'current'
    }
}

#endregion
