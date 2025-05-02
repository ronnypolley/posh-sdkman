. ..\PSSDKMan\Utils.ps1

function Get-Mocked-Grails-1.1.1-Locally-Available($Available) {
    if ( $Available ) {
        Mock Test-Is-Candidate-Version-Locally-Available { return $true }  -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
    } else {
        Mock Test-Is-Candidate-Version-Locally-Available { return $false }  -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
    }
}

function Get-Mocked-Api-Call-Grails-1.1.1-Available($Available) {
    if ( $Available ) {
        Mock Invoke-API-Call { return $true } -parameterFilter { $Path -eq 'candidates/validate/grails/1.1.1/cygwin' }
    } else {
        Mock Invoke-API-Call { return $false } -parameterFilter { $Path -eq 'candidates/validate/grails/1.1.1/cygwin' }
    }
}

function Get-Mocked-PSDK-Dir {
    $Script:backup_PSDK_DIR = $Global:PSDK_DIR
    $randomName = (-join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object {[char]$_}))
    $tempDir = [System.IO.Path]::GetTempPath()
    $testPath = "$tempDir\$randomName"
    New-Item -ItemType Directory "$testPath\.posh-sdk"
    $Global:PSDK_DIR = (Get-Item "$testPath\.posh-sdk" -Force).FullName
    New-Item -ItemType Directory "$Global:PSDK_DIR\grails" | Out-Null
}

function Reset-PSDK-Dir {
    $link = "$Global:PSDK_DIR\grails\current"
    if ( Test-Path $link ) {
        (Get-Item $link).Delete()
    }

    $Global:PSDK_DIR = $Script:backup_PSDK_DIR
}

function Initialize-Mocked-Grails-Home($Version) {
    $Script:backup_GRAILS_HOME = [System.Environment]::GetEnvironmentVariable('GRAILS_HOME')
    [System.Environment]::SetEnvironmentVariable('GRAILS_HOME', "$Global:PSDK_DIR\grails\$Version")
}

function Reset-Grails-Home {
    [System.Environment]::SetEnvironmentVariable('GRAILS_HOME', $Script:backup_GRAILS_HOME)
}

function Initialize-Mocked-Dispatcher-Test([switch]$Offline) {
    Get-Mocked-PSDK-Dir
    $Script:PSDK_FORCE_OFFLINE = $false
    $Script:FIRST_RUN = $false
    if ( !($Offline) ) {
        Mock Test-Available-Broadcast -verifiable
        Write-New-Version-Broadcast -verifiable
    }
    Mock Initialize-Candidate-Cache -verifiable
}

function Reset-Dispatcher-Test {
    Reset-PSDK-Dir
}
