BeforeAll {
    . ..\PSSDKMan\Utils.ps1
    . .\TestUtils.ps1
}

Describe 'Check-PSDK-API-Version' {
    Context 'API offline' {
        BeforeAll {
            $Script:GVM_AVAILABLE = $true
            $Script:GVM_API_NEW_VERSION = $false
            Mock Get-SDK-API-Version
            Mock Invoke-API-Call { throw 'error' }  -parameterFilter { $Path -eq 'app/Version' }
            Check-PSDK-API-Version
        }
        
        It 'the error handling set the app in offline mode' {
            $Script:GVM_AVAILABLE | Should -Be $false
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should -Be $false
        }
    }

    Context 'No new version' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $true
            $Script:GVM_API_NEW_VERSION = $false

            Mock Get-SDK-API-Version { 1.2.2 }
            Mock Invoke-API-Call { 1.2.2 } -parameterFilter { $Path -eq 'app/Version' }
            Mock Invoke-Self-Update

            Check-PSDK-API-Version 
        }

        It 'do nothing' {
            Assert-MockCalled Invoke-Self-Update 0
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }

    Context 'New version and no auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $false
            $Script:GVM_API_NEW_VERSION = $false

            Mock Get-SDK-API-Version { '1.2.2' }
            Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' }

            Check-PSDK-API-Version
        }

        It 'informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should -Be $true
        }

        It 'write a warning about needed update' {
            Assert-VerifiableMock
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }

    Context 'New version and auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $true
            $Script:GVM_API_NEW_VERSION = $false

            Mock Get-SDK-API-Version { '1.2.2' }
            Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' }
            Mock Invoke-Self-Update -verifiable

            Check-PSDK-API-Version 
        }

        It 'updates self' {
            Assert-VerifiableMock
        }

        It 'does not informs about new version' {
            $Script:GVM_API_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }
}

Describe 'Check-Posh-Gvm-Version' {
    Context 'No new Version' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $false
            $Script:PGVM_NEW_VERSION = $false

            Mock Is-New-Posh-GVM-Version-Available { $false }
            Mock Invoke-Self-Update

            Check-Posh-Gvm-Version
        }

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        It 'does not informs about new version' {
            $Script:PGVM_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }

    Context 'New version and no auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $false
            $Script:PGVM_NEW_VERSION = $false

            Mock Is-New-Posh-GVM-Version-Available { $true }
            Mock Invoke-Self-Update

            Check-Posh-Gvm-Version
        }

        It 'informs about new version' {
            $Script:PGVM_NEW_VERSION | Should -Be $true
        }

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }

    Context 'New version and auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PGVM_AUTO_SELFUPDTE = $Global:PGVM_AUTO_SELFUPDATE
            $Global:PGVM_AUTO_SELFUPDATE = $true
            $Script:PGVM_NEW_VERSION = $false

            Mock Is-New-Posh-GVM-Version-Available { $true }
            Mock Invoke-Self-Update -verifiable

            Check-Posh-Gvm-Version
        }

        It 'updates self' {
            Assert-VerifiableMock
        }

        It 'does not informs about new version' {
            $Script:PGVM_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PGVM_AUTO_SELFUPDATE = $Global:backup_Global_PGVM_AUTO_SELFUPDTE
        }
    }
}

Describe 'Is-New-Posh-GVM-Version-Available' {
    Context 'New version available' {
        BeforeAll {
            $Script:PGVM_VERSION_SERVICE = 'blub'
            $Script:PGVM_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PGVM_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { '1.2.1' } -parameterFilter { $Uri -eq 'blub' }
        }

        It 'returns $true' {
            $result = Is-New-Posh-GVM-Version-Available
            $result | Should -Be $true
        }
    }

    Context 'No new version available' {
        BeforeAll {
            $Script:PGVM_VERSION_SERVICE = 'blub'
            $Script:PGVM_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PGVM_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { '1.1.1' } -parameterFilter { $Uri -eq 'blub' }
        }
        
        It 'returns $false' {
            $result = Is-New-Posh-GVM-Version-Available
            $result | Should -Be $false
        }
    }

    Context 'Version service error' {
        BeforeAll { 
            $Script:PGVM_VERSION_SERVICE = 'blub'
            $Script:PGVM_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PGVM_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub' }
        }
        
        It 'returns $false' {
            $result = Is-New-Posh-GVM-Version-Available
            $result | Should -Be $false
        }
    }
}

Describe 'Get-SDK-API-Version' {
    Context 'No cached version' {
        BeforeAll { 
            $Script:PSDK_API_VERSION_PATH = 'TestDrive:version.txt' 
        }

        It 'returns `$null' {
            Get-SDK-API-Version | Should -Be $null
        }
    }

    Context 'No cached version' {
        BeforeAll {
            $Script:PSDK_API_VERSION_PATH = 'TestDrive:version.txt'
            Set-Content $Script:PSDK_API_VERSION_PATH '1.1.1'
        }

        It 'returns $null' {
            Get-SDK-API-Version | Should -Be 1.1.1
        }
    }
}

Describe 'Check-Available-Broadcast' {
    Context 'Last execution was online, still online' {
        BeforeAll {
            $Script:PSDK_ONLINE = $true
            $Script:GVM_AVAILABLE = $true
            Mock Get-SDK-API-Version { '1.2.3' }
            Mock Invoke-Broadcast-API-Call { 'Broadcast message' }
            Mock Handle-Broadcast -verifiable -parameterFilter { $Command -eq $null -and $Broadcast -eq 'Broadcast message' }
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

            Check-Available-Broadcast
        }

        It 'does not announce any mode changes' {
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 0
        }

        It 'calls Handle-Broadcast' {
            Assert-VerifiableMock
        }
    }

    Context 'Last execution was online, now offline' {
        BeforeAll {
            $Script:PSDK_ONLINE = $true
            $Script:GVM_AVAILABLE = $false
            Mock Get-SDK-API-Version { '1.2.4' }
            Mock Invoke-Broadcast-API-Call { $null }
            Mock Handle-Broadcast
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does announce offline mode' {
            Check-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 1
            Assert-MockCalled Write-Online-Broadcast 0
        }
        
        It 'does not call Handle-Broadcast' {
            Check-Available-Broadcast
            Assert-MockCalled Handle-Broadcast 0
        }
    }

    Context 'Last execution was offline, still offline' {
        BeforeAll {
            $Script:PSDK_ONLINE = $false
            $Script:GVM_AVAILABLE = $false
            Mock Get-SDK-API-Version { '1.2.4' }
            Mock Invoke-Broadcast-API-Call { $null }
            Mock Handle-Broadcast
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does not announce any mode changes' {
            Check-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 0
        }
        
        It 'does not call Handle-Broadcast' {
            Check-Available-Broadcast
            Assert-MockCalled Handle-Broadcast 0
        }
    }

    Context 'Last execution was offline, now online' {
        BeforeAll {
            $Script:PSDK_ONLINE = $false
            $Script:GVM_AVAILABLE = $true
            Mock Get-SDK-API-Version { '1.2.5' }
            Mock Invoke-Broadcast-API-Call { 'Broadcast message' }
            Mock Handle-Broadcast -verifiable -parameterFilter { $Command -eq $null -and $Broadcast -eq 'Broadcast message' }
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does announce online mode' {
            Check-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 1
        }
        
        It 'calls Handle-Broadcast' {
            Check-Available-Broadcast
            Assert-VerifiableMock
        }
    }
}

Describe 'Invoke-Self-Update' {
    Context 'Selfupdate will be triggered, no force, no new version' {
        BeforeAll {
            Mock Update-Candidates-Cache -verifiable
            Mock Write-Output -verifiable
            Mock Is-New-Posh-GVM-Version-Available { $false }
            Mock Invoke-Posh-Gvm-Update

            Invoke-Self-Update
        }

        It 'updates the candidate cache' {
            Assert-VerifiableMock
        }

        It 'does not updates itself' {
            Assert-MockCalled Invoke-Posh-Gvm-Update -Times 0
        }
    }

    Context 'Selfupdate will be triggered, no force, new version' {
        BeforeAll {
            Mock Update-Candidates-Cache -verifiable
            Mock Write-Output -verifiable
            Mock Is-New-Posh-GVM-Version-Available { $true }
            Mock Invoke-Posh-Gvm-Update -verifiable

            Invoke-Self-Update
        }

        It 'updates the candidate cache and version' {
            Assert-VerifiableMock
        }
    }

    Context 'Selfupdate will be triggered, force, no new version' {
        BeforeAll {
            Mock Update-Candidates-Cache -verifiable
            Mock Write-Output -verifiable
            Mock Is-New-Posh-GVM-Version-Available { $false }
            Mock Invoke-Posh-Gvm-Update -verifiable

            Invoke-Self-Update -Force $true
        }

        It 'updates the candidate cache and version' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Check-Candidate-Present checks if candidate parameter is valid' {
    It 'throws an error if no candidate is provided' {
        { Check-Candidate-Present } | Should -Throw
    }
    
    It 'throws error if candidate unknown' {
        $Script:SDK_CANDIDATES = @('grails', 'groovy')
        { Check-Candidate-Present java } | Should -Throw
    }

    It 'throws no error if candidate known' {
        $Script:SDK_CANDIDATES = @('grails', 'groovy')
        { Check-Candidate-Present groovy } | Should -Not -Throw
    }
}

Describe 'Check-Version-Present checks if version parameter is defined' {
    It 'throws an error if no candidate is provided' {
        { Check-Version-Present } | Should -Throw
    }

    It 'throws no error if version provided' {
        { Check-Version-Present 2.1.3 } | Should -Not -Throw
    }
}

Describe 'Check-Candidate-Version-Available select or vadidates a version for a candidate' {
    Context 'When grails version 1.1.1 is locally available' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Grails-1.1.1-Locally-Available $true
        }

        It 'check candidate parameter' {
            Check-Candidate-Version-Available grails 1.1.1
            Assert-VerifiableMock
        }

        It 'returns the 1.1.1' {
            $result = Check-Candidate-Version-Available grails 1.1.1
            $result | Should -Be 1.1.1
        }
    }

    Context 'When gvm is offline and the provided version is not locally available' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Offline
            Mock-Grails-1.1.1-Locally-Available $false
        }

        It 'throws an error' {
            { Check-Candidate-Version-Available grails 1.1.1 } | Should -Throw
        }

        It 'check candidate parameter' {
            Assert-VerifiableMock
        }
    }

    Context 'When gvm is offline and no version is provided but there is a current version' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Offline
            Mock-Current-Grails-1.2
        }

        It 'check candidate parameter' {
            Check-Candidate-Version-Available grails
            Assert-VerifiableMock
        }

        It 'returns the current version' {
            $result = Check-Candidate-Version-Available grails
            $result | Should -Be 1.2
        }
    }

    Context 'When gvm is offline and no version is provided and no current version is defined' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Offline
            Mock-No-Current-Grails
        }

        It 'throws an error' {
            { Check-Candidate-Version-Available grails } | Should -Throw
        }

        It 'check candidate parameter' {
            Assert-VerifiableMock
        }
    }

    Context 'When gvm is online and no version is provided' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Online
            Mock-Api-Call-Default-Grails-2.2
        }

    
        It 'the API default is returned' {
            $result = Check-Candidate-Version-Available grails
            $result | Should -Be 2.2
        }

        It 'check candidate parameter' {
            Check-Candidate-Version-Available grails
            Assert-VerifiableMock
        }
    }

    Context 'When gvm is online and the provided version is valid' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Online
            Mock-Api-Call-Grails-1.1.1-Available $true
        }

    
        It 'returns the version' {
            $result = Check-Candidate-Version-Available grails 1.1.1
            $result | Should -Be 1.1.1
        }
        
        It 'check candidate parameter' {
            Check-Candidate-Version-Available grails 1.1.1
            Assert-VerifiableMock
        }
    }

    Context 'When gvm is online and the provided version is invalid' {
        BeforeAll {
            Mock-Check-Candidate-Grails
            Mock-Online
            Mock-Api-Call-Grails-1.1.1-Available $false
        }

        It 'throws an error' {
            { Check-Candidate-Version-Available grails 1.1.1 } | Should -Throw
        }

        It 'check candidate parameter' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Get-Current-Candidate-Version reads the currently linked version' {
    Context 'When current is not defined' {
        BeforeAll {
            Mock-PSDK-Dir
        }

        It 'returns $null if current not defined' {
            Get-Current-Candidate-Version grails | Should -Be $null
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'When current is defined' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\2.2.2" | Out-Null
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\current" "$Global:PSDK_DIR\grails\2.2.2"
        }

        It 'returns the liked version' {
            Get-Current-Candidate-Version grails | Should -Be 2.2.2
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Get-Env-Candidate-Version reads the version set in $Candidate-Home' {
    Context 'When GRAILS_HOME is set to a specific version' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\2.2.1" | Out-Null
            Mock-Grails-Home 2.2.1
        }

        It 'returns the set version' {
            Get-Env-Candidate-Version grails | Should -Be 2.2.1
        }

        AfterAll {
            Reset-Grails-Home
            Reset-PSDK-Dir
        }
    }

    Context 'When GRAILS_HOME is set to current' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\2.2.1" | Out-Null
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\current" "$Global:PSDK_DIR\grails\2.2.1"

            Mock-Grails-Home current
        }

        It 'returns the version linked to current' {
            Get-Env-Candidate-Version grails | Should -Be 2.2.1
        }

        AfterAll {
            Reset-Grails-Home
            Reset-PSDK-Dir
        }
    }
}

Describe 'Check-Candidate-Version-Locally-Available throws error message if not available' {
    Context 'Version not available' {
        It 'throws an error' {
            Mock-Grails-1.1.1-Locally-Available $false
            { Check-Candidate-Version-Locally-Available grails 1.1.1 } | Should -Throw
        }
    }

    Context 'Version is available' {
        
        It 'not throws any error' {
            Mock-Grails-1.1.1-Locally-Available $true
            { Check-Candidate-Version-Locally-Available grails 1.1.1 } | Should -Not -Throw
        }
    }
}

Describe 'Is-Candidate-Version-Locally-Available check the path exists' {
    Context 'No version provided' {
        it 'returns $false' {
            Is-Candidate-Version-Locally-Available grails | Should -Be $false
        }
    }

    Context 'COC path for grails 1.1.1 is missing' {
        
        it 'returns $false' {
            Mock-PSDK-Dir
            Is-Candidate-Version-Locally-Available grails 1.1.1 | Should -Be $false
            Reset-PSDK-Dir
        }

    }

    Context 'COC path for grails 1.1.1 exists' {
        
        it 'returns $true' {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.1.1" | Out-Null
            Is-Candidate-Version-Locally-Available grails 1.1.1 | Should -Be $true
            Reset-PSDK-Dir
        }

    }
}

Describe 'Get-Installed-Candidate-Version-List' {
    Context 'Version 1.1, 1.3.7 and 2.2.1 of grails installed' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.1" | Out-Null
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\2.2.1" | Out-Null
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\current" "$Global:PSDK_DIR\grails\2.2.1"
        }

        It 'returns list of installed versions' {
            Get-Installed-Candidate-Version-List grails | Should -Be 1.1, 1.3.7, 2.2.1
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Set-Env-Candidate-Version' {
    Context 'Env-Version of grails is current' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\2.2.1" | Out-Null
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\current" "$Global:PSDK_DIR\grails\2.2.1"
            Mock-Grails-Home current
            $Global:backupPATH = $env:Path

            Set-Env-Candidate-Version grails 1.3.7
        }

        It 'sets GRAILS_HOME' {
            $env:GRAILS_HOME -eq "$Global:PSDK_DIR\grails\1.3.7"
        }

        It 'extends the Path' {
            $env:Path -eq "$Global:PSDK_DIR\grails\1.3.7\bin"
        }

        AfterAll {
            $env:Path = $Global:backupPATH
            Reset-Grails-Home
            Reset-PSDK-Dir
        }
    }
}

Describe 'Set-Linked-Candidate-Version' {
    Context 'In a initialized PGVM-Dir' {
        BeforeAll {
            Mock-PSDK-Dir
            Mock Set-Junction-Via-Mklink -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }

            Set-Linked-Candidate-Version grails 2.2.1
        }

        It 'calls Set-Junction-Via-Mklink with the correct paths' {
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Set-Junction-Via-Mklink' {
    Context 'No junction for the link-path exists' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null

            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\bla" "$Global:PSDK_DIR\grails\1.3.7"
        }

        It 'creates a junction to the target location' {
            (Get-Junction-Target "$Global:PSDK_DIR\grails\bla").FullName -eq "$Global:PSDK_DIR\grails\1.3.7" 
        }

        AfterAll {
            (Get-Item "$Global:PSDK_DIR\grails\bla").Delete()
            Reset-PSDK-Dir
        }
    }

    Context 'A Junction for the link-path exists' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.8" | Out-Null
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\bla" "$Global:PSDK_DIR\grails\1.3.8"
            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\bla" "$Global:PSDK_DIR\grails\1.3.7"
        }

        It 'creates a junction to the target location without errors' {
            (Get-Junction-Target "$Global:PSDK_DIR\grails\bla").FullName -eq "$Global:PSDK_DIR\grails\1.3.7"
        }

        AfterAll {
            (Get-Item "$Global:PSDK_DIR\grails\bla").Delete()
            Reset-PSDK-Dir
        }
    }
}

Describe 'Get-Junction-Target' {
    Context 'Provided path is a junction' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null

            Set-Junction-Via-Mklink "$Global:PSDK_DIR\grails\bla" "$Global:PSDK_DIR\grails\1.3.7"
        }

        It 'returns the item of the junction correctly' {
            (Get-Junction-Target "$Global:PSDK_DIR\grails\bla").FullName -eq "$Global:PSDK_DIR\grails\1.3.7"
        }

        AfterAll {
            (Get-Item "$Global:PSDK_DIR\grails\bla").Delete()
            Reset-PSDK-Dir
        }
    }

    Context 'Provided path is no junction' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.3.7" | Out-Null
        }

        It 'returns correctly a null object without exception' {
            Get-Junction-Target "$Global:PSDK_DIR\grails\1.3.7" -eq $null
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Get-Online-Mode check the state variables for GVM-API availablitiy and for force offline mode' {
    Context 'GVM-Api unavailable but may be connected' {
        
        It 'returns $false' {
            $Script:GVM_AVAILABLE = $false
            $Script:SDK_FORCE_OFFLINE = $false
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'GVM-Api unavailable and may not be connected' {
        
        It 'returns $false' {
            $Script:GVM_AVAILABLE = $false
            $Script:SDK_FORCE_OFFLINE = $true
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'GVM-Api is available and may not be connected' {
        
        It 'returns $false' {
            $Script:GVM_AVAILABLE = $true
            $Script:SDK_FORCE_OFFLINE = $true
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'GVM-Api is available and may be connected' {
        
        It 'returns $true' {
            $Script:GVM_AVAILABLE = $true
            $Script:SDK_FORCE_OFFLINE = $false
            Get-Online-Mode | Should -Be $true
        }
    }
}


Describe 'Check-Online-Mode throws an error when offline' {
    Context 'Offline' {
        
        It 'throws an error' {
            Mock-Offline
            { Check-Online-Mode } | Should -Throw
        }
    }

    Context 'Online' {
        
        It 'throws no error' {
            Mock-Online
            { Check-Online-Mode } | Should -Not -Throw
        }
    }
}

Describe 'Invoke-API-Call helps doing calls to the GVM-API' {
    Context 'Successful API call only with API path' {
        
        It 'returns the result from Invoke-RestMethod' {
            $Script:PGVM_SERVICE = 'blub'
            Mock Invoke-RestMethod { 'called' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Invoke-API-Call 'na/rock' | Should -Be 'called'
        }
    }

    Context 'Failed API call only with API path' {
        BeforeAll {
            $Script:PGVM_SERVICE = 'blub'
            $Script:GVM_AVAILABLE = $true
            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Mock Check-Online-Mode -verifiable

            Invoke-API-Call 'na/rock'
        }

        It 'sets GVM_AVAILABLE to false' {
            $Script:GVM_AVAILABLE | Should -Be $false
        }

        It 'calls Check-Online-Mode which throws an error' {
            Assert-VerifiableMock
        }
    }

    Context 'Failed API call with API path and IgnoreFailure' {
        BeforeAll {
            $Script:PGVM_SERVICE = 'blub'
            $Script:GVM_AVAILABLE = $true
            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Mock Check-Online-Mode

            Invoke-API-Call 'na/rock' -IgnoreFailure
        }

        It 'sets GVM_AVAILABLE to false' {
            $Script:GVM_AVAILABLE | Should -Be $false
        }

        It 'do not call Check-Online-Mode' {
            Assert-MockCalled Check-Online-Mode 0
        }
    }

    Context 'Successful API call with API path and FilePath' {
        BeforeAll {
            $Script:PGVM_SERVICE = 'blub'
            Mock Invoke-RestMethod -verifiable -parameterFilter { $Uri -eq 'blub/na/rock' -and $OutFile -eq 'TestDrive:a.txt' }

            Invoke-API-Call 'na/rock' TestDrive:a.txt
        }

        It 'calls Invoke-RestMethod with file path' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Cleanup-Directory' {
    Context 'Directory with subdirectories and files' {
        BeforeAll {
            New-Item -ItemType Directory TestDrive:bla | Out-Null
            New-Item -ItemType Directory TestDrive:bla\a | Out-Null
            New-Item -ItemType Directory TestDrive:bla\b | Out-Null
            New-Item -ItemType File TestDrive:bla\c | Out-Null
            New-Item -ItemType File TestDrive:bla\a\a | Out-Null

            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq '2 archive(s) flushed, freeing 0 MB' }

            Cleanup-Directory TestDrive:bla
        }

        It 'Cleans the Test-Path file' {
            Test-Path TestDrive:bla | Should -Be $False
        }

        It 'Write info to host' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Handle-Broadcast' {
    Context 'Cache broadcast message different than new broadcast' {
        BeforeAll {
            Mock-PSDK-Dir
            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Set-Content $Script:PSDK_BROADCAST_PATH 'Old Broadcast message'
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'New Broadcast message' }

            Handle-Broadcast list 'New Broadcast message'
        }

        It 'outputs the broadcast message' {
            Assert-VerifiableMock
        }

        It 'sets the new broadcast message in file' {
            Get-Content $Script:PSDK_BROADCAST_PATH | Should -Be 'New Broadcast message'
        }


        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'No cached broadcast message' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'New Broadcast message' }

            Handle-Broadcast list 'New Broadcast message'
        }

        It 'outputs the broadcast message' {
            Assert-VerifiableMock
        }

        It 'sets the new broadcast message in file' {
            Get-Content $Script:PSDK_BROADCAST_PATH | Should -Be 'New Broadcast message'
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'b do not print the new broadcast message' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Mock Write-Output -verifiable

            Handle-Broadcast b 'New Broadcast message'
        }

        It 'no Broadcast' {
            Assert-MockCalled Write-Output 0
        }

        It 'sets the new broadcast message in file' {
            Test-Path $Script:PSDK_BROADCAST_PATH | Should -Be $false
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'Broadcast do nOt print the new broadcast message' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Mock Write-Output -verifiable

            Handle-Broadcast broadcast 'New Broadcast message'
        }

        It 'no Broadcast' {
            Assert-MockCalled Write-Output 0
        }

        It 'sets the new broadcast message in file' {
            Test-Path $Script:PSDK_BROADCAST_PATH | Should -Be $false
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'selfupdate do not print the new broadcast message' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Mock Write-Output -verifiable

            Handle-Broadcast selfupdate 'New Broadcast message'
        }

        It 'no Broadcast' {
            Assert-MockCalled Write-Output 0
        }

        It 'sets the new broadcast message in file' {
            Test-Path $Script:PSDK_BROADCAST_PATH | Should -Be $false
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'flush do not print the new broadcast message' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Mock Write-Output -verifiable

            Handle-Broadcast flush 'New Broadcast message'
        }

        It 'no Broadcast' {
            Assert-MockCalled Write-Output 0
        }

        It 'sets the new broadcast message in file' {
            Test-Path $Script:PSDK_BROADCAST_PATH | Should -Be $false
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Init-Candidate-Cache' {
    Context 'Candidate cache file does not exists' {
        BeforeAll {
            Mock-PSDK-Dir
            $Script:PSDK_CANDIDATES_PATH = "$Global:PSDK_DIR\candidates.txt"
        }

        It 'throws an error' {
            { Init-Candidate-Cache } | Should -Throw
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'Candidate cache file does exists' {
        BeforeAll {
            Mock-PSDK-Dir
            $Script:PSDK_CANDIDATES_PATH = "$Global:PSDK_DIR\candidates.txt"
            Set-Content $Script:PSDK_CANDIDATES_PATH 'grails,groovy,test'
            $Script:SDK_CANDIDATES = $null

            Init-Candidate-Cache
        }

        It 'sets `$Script:SDK_CANDIDATES' {
            $Script:SDK_CANDIDATES | Should -Be grails, groovy, test
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Update-Candidate-Cache' {
    Context 'Checks online mode and than get version and candidates from api' {
        BeforeAll {
            Mock-PSDK-Dir

            $Script:PSDK_API_VERSION_PATH = "$Global:PSDK_DIR\version.txt"
            $Script:PSDK_CANDIDATES_PATH = "$Global:PSDK_DIR\candidates.txt"

            Mock Check-Online-Mode -verifiable
            Mock Invoke-API-Call -verifiable -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' -and $FileTarget -eq "$Global:PSDK_DIR\version.txt" }
            Mock Invoke-API-Call -verifiable -parameterFilter { $Path -eq 'candidates/all' -and $FileTarget -eq "$Global:PSDK_DIR\candidates.txt" }

            Update-Candidates-Cache
        }

        It 'calls the Check-Online-Mode and two API paths' {
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Write-Offline-Version-List' {
    Context 'no versions of grails installed' {
        BeforeAll {
            Mock Write-Output
            Mock Get-Current-Candidate-Version { $null } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Installed-Candidate-Version-List { $null } -parameterFilter { $Candidate -eq 'grails' }
        }

        It 'Outputs 11 lines' {
            Write-Offline-Version-List grails
            Assert-MockCalled Write-Output 9
        }
    }

    Context 'Three versions of grails installed' {
        BeforeAll {
            Mock Write-Output
            Mock Get-Current-Candidate-Version { 1.1.1 } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Installed-Candidate-Version-List { 1.1.1, 2.2.2, 2.3.0 } -parameterFilter { $Candidate -eq 'grails' }
        }
        
        It 'Outputs 11 lines' {
            Write-Offline-Version-List grails
            Assert-MockCalled Write-Output 11
        }
    }
}

Describe 'Write-Version-List' {
    Context 'Three versions of grails installed' {
        BeforeAll {
            Mock Write-Output
            Mock Get-Current-Candidate-Version { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Installed-Candidate-Version-List { return '1.1.1', '2.2.2', '2.3.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Invoke-API-Call { 'bla' } -parameterFilter { $Path -eq 'candidates/grails/cygwin/versions/list?current=1.1.1&installed=1.1.1,2.2.2,2.3.0' }
        }
        
        It 'writes to host' {
            Write-Version-List grails
            Assert-MockCalled Write-Output 1
        }
    }
}

Describe 'Install-Local-Version' {
    Context 'LocalPath is no directory' {
        It 'throws an error' {
            New-Item -ItemType File TestDrive:a.txt | Out-Null
            { Install-Local-Version grails snapshot TestDrive:a.txt } | Should -Throw
        }
    }

    Context 'LocalPath is valid' {
        BeforeAll {
            New-Item -ItemType Directory TestDrive:Snapshot | Out-Null
            Mock Write-Output
            Mock Set-Junction-Via-Mklink -verifiable -parameterFilter { $Link -eq "$Global:PSDK_DIR\grails\snapshot" -and $Target -eq 'TestDrive:Snapshot' }

            Install-Local-Version grails snapshot TestDrive:Snapshot
        }

        It 'creates junction for candidate version' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Install-Remote-Version' {
    Context 'Install of a valid version without local archive' {
        BeforeAll {
            Mock-PSDK-Dir

            Mock Write-Output
            Mock Check-Online-Mode -verifiable
            $Script:PGVM_SERVICE = 'foobar'
            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            $testFilePath = "$PSScriptRoot\test\grails-1.3.9.zip"

            Mock -CommandName Download-File -verifiable -MockWith { Copy-Item $testFilePath "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip" } -ParameterFilter { $Url -eq 'foobar/broker/download/grails/1.3.9/cygwin' -and $TargetFile -eq "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip" }

            Install-Remote-Version grails 1.3.9
        }

        It 'downloads the archive' {
            Assert-VerifiableMock
        }

        It 'install it correctly' {
            Test-Path "$Global:PSDK_DIR\grails\1.3.9\bin\grails" | Should -Be $true
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'Install of a valid version with local archive' {
        BeforeAll {
            Mock-PSDK-Dir

            Mock Write-Output
            Mock Download-File

            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            New-Item -ItemType Directory $Script:PSDK_ARCHIVES_PATH | Out-Null
            Copy-Item "$PSScriptRoot\test\grails-1.3.9.zip" "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip"

            Install-Remote-Version grails 1.3.9
        }

        It 'does not download the archive again' {
            Assert-MockCalled Download-File 0
        }

        It 'install it correctly' {
            Test-Path "$Global:PSDK_DIR\grails\1.3.9\bin\grails" | Should -Be $true
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'Install of a currupt archive' {
        BeforeAll {
            Mock-PSDK-Dir

            Mock Write-Output
            Mock Download-File

            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            New-Item -ItemType Directory $Script:PSDK_ARCHIVES_PATH | Out-Null
            Copy-Item "$PSScriptRoot\test\grails-2.2.2.zip" "$Script:PSDK_ARCHIVES_PATH\grails-2.2.2.zip"
        }

        It 'fails because of no unziped files' {
            { Install-Remote-Version grails 2.2.2 } | Should -Throw
        }

        It 'does not download the archive again' {
            Assert-MockCalled Download-File 0
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}
