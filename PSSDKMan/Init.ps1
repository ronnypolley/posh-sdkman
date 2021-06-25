#region Initialization
function Initialize-Posh-SDK() {
    Write-Verbose 'Init posh-sdk'

    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    Test-JAVA-HOME

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

function Test-JAVA-HOME() {
	# Check for JAVA_HOME, If not set, try to interfere it
    if ( ! (Test-Path env:JAVA_HOME) ) {
        try {
            [Environment]::SetEnvironmentVariable('JAVA_HOME', (Get-Item (Get-Command 'javac').Path).Directory.Parent.FullName)
        } catch {
            throw "Could not find java, please set JAVA_HOME"
        }
    }
}

#endregion
