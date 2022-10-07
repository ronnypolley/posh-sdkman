BeforeAll {
    . ..\PSSDKMan\Utils.ps1
    . .\TestUtils.ps1
}

Describe 'Test-SDKMAN-API-Version' {
    Context 'API offline' {
        BeforeAll {
            $Script:PSDK_AVAILABLE = $true
            $Script:PSDK_API_NEW_VERSION = $false
            Mock Get-SDKMAN-API-Version
            Mock Invoke-API-Call { throw 'error' }  -parameterFilter { $Path -eq 'app/Version' }
            Test-SDKMAN-API-Version
        }
        
        It 'the error handling set the app in offline mode' {
            $Script:PSDK_AVAILABLE | Should -Be $false
        }

        It 'does not informs about new version' {
            $Script:PSDK_API_NEW_VERSION | Should -Be $false
        }
    }

    Context 'No new version' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $true
            $Script:PSDK_API_NEW_VERSION = $false

            Mock Get-SDKMAN-API-Version { 1.2.2 }
            Mock Invoke-API-Call { 1.2.2 } -parameterFilter { $Path -eq 'app/Version' }
            Mock Invoke-Self-Update

            Test-SDKMAN-API-Version 
        }

        It 'do nothing' {
            Assert-MockCalled Invoke-Self-Update 0
        }

        It 'does not informs about new version' {
            $Script:PSDK_API_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }

    Context 'New version and no auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $false
            $Script:PSDK_API_NEW_VERSION = $false

            Mock Get-SDKMAN-API-Version { '1.2.2' }
            Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' }

            Test-SDKMAN-API-Version
        }

        It 'informs about new version' {
            $Script:PSDK_API_NEW_VERSION | Should -Be $true
        }

        It 'write a warning about needed update' {
            Assert-VerifiableMock
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }

    Context 'New version and auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $true
            $Script:PSDK_API_NEW_VERSION = $false

            Mock Get-SDKMAN-API-Version { '1.2.2' }
            Mock Invoke-API-Call { '1.2.3' } -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' }
            Mock Invoke-Self-Update -verifiable

            Test-SDKMAN-API-Version 
        }

        It 'updates self' {
            Assert-VerifiableMock
        }

        It 'does not informs about new version' {
            $Script:PSDK_API_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }
}

Describe 'Test-Posh-SDK-Version' {
    Context 'No new Version' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $false
            $Script:PSDK_NEW_VERSION = $false

            Mock Test-New-Posh-SDK-Version-Available { $false }
            Mock Invoke-Self-Update

            Test-Posh-SDK-Version
        }

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        It 'does not informs about new version' {
            $Script:PSDK_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }

    Context 'New version and no auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $false
            $Script:PSDK_NEW_VERSION = $false

            Mock Test-New-Posh-SDK-Version-Available { $true }
            Mock Invoke-Self-Update

            Test-Posh-SDK-Version
        }

        It 'informs about new version' {
            $Script:PSDK_NEW_VERSION | Should -Be $true
        }

        It 'does not update itself' {
            Assert-MockCalled Invoke-Self-Update -Times 0
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }

    Context 'New version and auto selfupdate' {
        BeforeAll {
            $Global:backup_Global_PSDK_AUTO_SELFUPDTE = $Global:PSDK_AUTO_SELFUPDATE
            $Global:PSDK_AUTO_SELFUPDATE = $true
            $Script:PSDK_NEW_VERSION = $false

            Mock Test-New-Posh-SDK-Version-Available { $true }
            Mock Invoke-Self-Update -verifiable

            Test-Posh-SDK-Version
        }

        It 'updates self' {
            Assert-VerifiableMock
        }

        It 'does not informs about new version' {
            $Script:PSDK_NEW_VERSION | Should -Be $false
        }

        AfterAll {
            $Global:PSDK_AUTO_SELFUPDATE = $Global:backup_Global_PSDK_AUTO_SELFUPDTE
        }
    }
}

Describe 'Test-New-Posh-SDK-Version-Available' {
    Context 'New version available' {
        BeforeAll {
            $Script:PSDK_VERSION_SERVICE = 'blub'
            $Script:PSDK_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PSDK_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { '1.2.1' } -parameterFilter { $Uri -eq 'blub' }
        }

        It 'returns $true' {
            $result = Test-New-Posh-SDK-Version-Available
            $result | Should -Be $true
        }
    }

    Context 'No new version available' {
        BeforeAll {
            $Script:PSDK_VERSION_SERVICE = 'blub'
            $Script:PSDK_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PSDK_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { '1.1.1' } -parameterFilter { $Uri -eq 'blub' }
        }
        
        It 'returns $false' {
            $result = Test-New-Posh-SDK-Version-Available
            $result | Should -Be $false
        }
    }

    Context 'Version service error' {
        BeforeAll { 
            $Script:PSDK_VERSION_SERVICE = 'blub'
            $Script:PSDK_VERSION_PATH = 'TestDrive:VERSION.txt'
            Set-Content $Script:PSDK_VERSION_PATH '1.1.1'

            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub' }
        }
        
        It 'returns $false' {
            $result = Test-New-Posh-SDK-Version-Available
            $result | Should -Be $false
        }
    }
}

Describe 'Get-SDKMAN-API-Version' {
    Context 'No cached version' {
        BeforeAll { 
            $Script:PSDK_API_VERSION_PATH = 'TestDrive:version.txt' 
        }

        It 'returns `$null' {
            Get-SDKMAN-API-Version | Should -Be $null
        }
    }

    Context 'No cached version' {
        BeforeAll {
            $Script:PSDK_API_VERSION_PATH = 'TestDrive:version.txt'
            Set-Content $Script:PSDK_API_VERSION_PATH '1.1.1'
        }

        It 'returns $null' {
            Get-SDKMAN-API-Version | Should -Be 1.1.1
        }
    }
}

Describe 'Test-Available-Broadcast' {
    Context 'Last execution was online, still online' {
        BeforeAll {
            $Script:PSDK_ONLINE = $true
            $Script:PSDK_AVAILABLE = $true
            Mock Get-SDKMAN-API-Version { '1.2.3' }
            Mock Invoke-Broadcast-API-Call { 'Broadcast message' }
            Mock Resolve-Broadcast -verifiable -parameterFilter { $Command -eq $null -and $Broadcast -eq 'Broadcast message' }
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

            Test-Available-Broadcast
        }

        It 'does not announce any mode changes' {
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 0
        }

        It 'calls Resolve-Broadcast' {
            Assert-VerifiableMock
        }
    }

    Context 'Last execution was online, now offline' {
        BeforeAll {
            $Script:PSDK_ONLINE = $true
            $Script:PSDK_AVAILABLE = $false
            Mock Get-SDKMAN-API-Version { '1.2.4' }
            Mock Invoke-Broadcast-API-Call { $null }
            Mock Resolve-Broadcast
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does announce offline mode' {
            Test-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 1
            Assert-MockCalled Write-Online-Broadcast 0
        }
        
        It 'does not call Resolve-Broadcast' {
            Test-Available-Broadcast
            Assert-MockCalled Resolve-Broadcast 0
        }
    }

    Context 'Last execution was offline, still offline' {
        BeforeAll {
            $Script:PSDK_ONLINE = $false
            $Script:PSDK_AVAILABLE = $false
            Mock Get-SDKMAN-API-Version { '1.2.4' }
            Mock Invoke-Broadcast-API-Call { $null }
            Mock Resolve-Broadcast
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does not announce any mode changes' {
            Test-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 0
        }
        
        It 'does not call Resolve-Broadcast' {
            Test-Available-Broadcast
            Assert-MockCalled Resolve-Broadcast 0
        }
    }

    Context 'Last execution was offline, now online' {
        BeforeAll {
            $Script:PSDK_ONLINE = $false
            $Script:PSDK_AVAILABLE = $true
            Mock Get-SDKMAN-API-Version { '1.2.5' }
            Mock Invoke-Broadcast-API-Call { 'Broadcast message' }
            Mock Resolve-Broadcast -verifiable -parameterFilter { $Command -eq $null -and $Broadcast -eq 'Broadcast message' }
            Mock Write-Offline-Broadcast
            Mock Write-Online-Broadcast

        }
        
        It 'does announce online mode' {
            Test-Available-Broadcast
            Assert-MockCalled Write-Offline-Broadcast 0
            Assert-MockCalled Write-Online-Broadcast 1
        }
        
        It 'calls Resolve-Broadcast' {
            Test-Available-Broadcast
            Assert-VerifiableMock
        }
    }
}

Describe 'Invoke-Self-Update' {
    Context 'Selfupdate will be triggered, no force, no new version' {
        BeforeAll {
            Mock Update-Candidates-Cache -verifiable
            Mock Write-Output -verifiable
            Mock Test-New-Posh-SDK-Version-Available { $false }
            Mock Invoke-Posh-SDK-Update

            Invoke-Self-Update
        }

        It 'updates the candidate cache' {
            Assert-VerifiableMock
        }

        It 'does not updates itself' {
            Assert-MockCalled Invoke-Posh-SDK-Update -Times 0
        }
    }

    Context 'Selfupdate will be triggered, no force, new version' {
        BeforeAll {
            Mock Update-Candidates-Cache -verifiable
            Mock Write-Output -verifiable
            Mock Test-New-Posh-SDK-Version-Available { $true }
            Mock Invoke-Posh-SDK-Update -verifiable

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
            Mock Test-New-Posh-SDK-Version-Available { $false }
            Mock Invoke-Posh-SDK-Update -verifiable

            Invoke-Self-Update -Force $true
        }

        It 'updates the candidate cache and version' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Test-Candidate-Present checks if candidate parameter is valid' {
    It 'throws an error if no candidate is provided' {
        { Test-Candidate-Present } | Should -Throw
    }
    
    It 'throws error if candidate unknown' {
        $Script:SDK_CANDIDATES = @('grails', 'groovy')
        { Test-Candidate-Present java } | Should -Throw
    }

    It 'throws no error if candidate known' {
        $Script:SDK_CANDIDATES = @('grails', 'groovy')
        { Test-Candidate-Present groovy } | Should -Not -Throw
    }
}

Describe 'Test-Version-Present checks if version parameter is defined' {
    It 'throws an error if no candidate is provided' {
        { Test-Version-Present } | Should -Throw
    }

    It 'throws no error if version provided' {
        { Test-Version-Present 2.1.3 } | Should -Not -Throw
    }
}

Describe 'Test-Candidate-Version-Available select or vadidates a version for a candidate' {
    Context 'When grails version 1.1.1 is locally available' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock-Grails-1.1.1-Locally-Available $true
        }

        It 'check candidate parameter' {
            Test-Candidate-Version-Available grails 1.1.1
            Assert-VerifiableMock
        }

        It 'returns the 1.1.1' {
            $result = Test-Candidate-Version-Available grails 1.1.1
            $result | Should -Be 1.1.1
        }
    }

    Context 'When sdk is offline and the provided version is not locally available' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $false }
            Mock-Grails-1.1.1-Locally-Available $false
        }

        It 'throws an error' {
            { Test-Candidate-Version-Available grails 1.1.1 } | Should -Throw
        }

        It 'check candidate parameter' {
            Assert-VerifiableMock
        }
    }

    Context 'When sdk is offline and no version is provided but there is a current version' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $false }
            Mock Get-Current-Candidate-Version { return 1.2 } -parameterFilter { $Candidate -eq 'grails' }
        }

        It 'check candidate parameter' {
            Test-Candidate-Version-Available grails
            Assert-VerifiableMock
        }

        It 'returns the current version' {
            $result = Test-Candidate-Version-Available grails
            $result | Should -Be 1.2
        }
    }

    Context 'When sdk is offline and no version is provided and no current version is defined' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $false }
            Mock Get-Current-Candidate-Version { return $null } -parameterFilter { $Candidate -eq 'grails' }
        }

        It 'throws an error' {
            { Test-Candidate-Version-Available grails } | Should -Throw
        }

        It 'check candidate parameter' {
            Assert-VerifiableMock
        }
    }

    Context 'When sdk is online and no version is provided' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $true }
            Mock Invoke-API-Call { return 2.2 } -parameterFilter { $Path -eq 'candidates/default/grails' }
        }

    
        It 'the API default is returned' {
            $result = Test-Candidate-Version-Available grails
            $result | Should -Be 2.2
        }

        It 'check candidate parameter' {
            Test-Candidate-Version-Available grails
            Assert-VerifiableMock
        }
    }

    Context 'When sdk is online and the provided version is valid' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $true }
            Mock-Api-Call-Grails-1.1.1-Available $true
        }

    
        It 'returns the version' {
            $result = Test-Candidate-Version-Available grails 1.1.1
            $result | Should -Be 1.1.1
        }
        
        It 'check candidate parameter' {
            Test-Candidate-Version-Available grails 1.1.1
            Assert-VerifiableMock
        }
    }

    Context 'When sdk is online and the provided version is invalid' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Online-Mode { return $true }
            Mock-Api-Call-Grails-1.1.1-Available $false
        }

        It 'throws an error' {
            { Test-Candidate-Version-Available grails 1.1.1 } | Should -Throw
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

Describe 'Test-Candidate-Version-Locally-Available throws error message if not available' {
    Context 'Version not available' {
        It 'throws an error' {
            Mock-Grails-1.1.1-Locally-Available $false
            { Test-Candidate-Version-Locally-Available grails 1.1.1 } | Should -Throw
        }
    }

    Context 'Version is available' {
        
        It 'not throws any error' {
            Mock-Grails-1.1.1-Locally-Available $true
            { Test-Candidate-Version-Locally-Available grails 1.1.1 } | Should -Not -Throw
        }
    }
}

Describe 'Test-Is-Candidate-Version-Locally-Available check the path exists' {
    Context 'No version provided' {
        it 'returns $false' {
            Test-Is-Candidate-Version-Locally-Available grails | Should -Be $false
        }
    }

    Context 'COC path for grails 1.1.1 is missing' {
        
        it 'returns $false' {
            Mock-PSDK-Dir
            Test-Is-Candidate-Version-Locally-Available grails 1.1.1 | Should -Be $false
            Reset-PSDK-Dir
        }

    }

    Context 'COC path for grails 1.1.1 exists' {
        
        it 'returns $true' {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\1.1.1" | Out-Null
            Test-Is-Candidate-Version-Locally-Available grails 1.1.1 | Should -Be $true
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
    Context 'In a initialized PSDK-Dir' {
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

Describe 'Get-Online-Mode check the state variables for PSDK-API availablitiy and for force offline mode' {
    Context 'PSDK-Api unavailable but may be connected' {
        
        It 'returns $false' {
            $Script:PSDK_AVAILABLE = $false
            $Script:PSDK_FORCE_OFFLINE = $false
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'PSDK-Api unavailable and may not be connected' {
        
        It 'returns $false' {
            $Script:PSDK_AVAILABLE = $false
            $Script:PSDK_FORCE_OFFLINE = $true
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'PSDK-Api is available and may not be connected' {
        
        It 'returns $false' {
            $Script:PSDK_AVAILABLE = $true
            $Script:PSDK_FORCE_OFFLINE = $true
            Get-Online-Mode | Should -Be $false
        }
    }

    Context 'PSDK-Api is available and may be connected' {
        
        It 'returns $true' {
            $Script:PSDK_AVAILABLE = $true
            $Script:PSDK_FORCE_OFFLINE = $false
            Get-Online-Mode | Should -Be $true
        }
    }
}


Describe 'Test-Online-Mode throws an error when offline' {
    Context 'Offline' {
        
        It 'throws an error' {
            Mock Get-Online-Mode { return $false }
            { Test-Online-Mode } | Should -Throw
        }
    }

    Context 'Online' {
        
        It 'throws no error' {
            Mock Get-Online-Mode { return $true }
            { Test-Online-Mode } | Should -Not -Throw
        }
    }
}

Describe 'Invoke-API-Call helps doing calls to the PSDK-Api' {
    Context 'Successful API call only with API path' {
        
        It 'returns the result from Invoke-RestMethod' {
            $Script:PSDK_SERVICE = 'blub'
            Mock Invoke-RestMethod { 'called' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Invoke-API-Call 'na/rock' | Should -Be 'called'
        }
    }

    Context 'Failed API call only with API path' {
        BeforeAll {
            $Script:PSDK_SERVICE = 'blub'
            $Script:PSDK_AVAILABLE = $true
            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Mock Test-Online-Mode -verifiable

            Invoke-API-Call 'na/rock'
        }

        It 'sets SDK_AVAILABLE to false' {
            $Script:PSDK_AVAILABLE | Should -Be $false
        }

        It 'calls Test-Online-Mode which throws an error' {
            Assert-VerifiableMock
        }
    }

    Context 'Failed API call with API path and IgnoreFailure' {
        BeforeAll {
            $Script:PSDK_SERVICE = 'blub'
            $Script:PSDK_AVAILABLE = $true
            Mock Invoke-RestMethod { throw 'error' } -parameterFilter { $Uri -eq 'blub/na/rock' }
            Mock Test-Online-Mode

            Invoke-API-Call 'na/rock' -IgnoreFailure
        }

        It 'sets SDK_AVAILABLE to false' {
            $Script:PSDK_AVAILABLE | Should -Be $false
        }

        It 'do not call Test-Online-Mode' {
            Assert-MockCalled Test-Online-Mode 0
        }
    }

    Context 'Successful API call with API path and FilePath' {
        BeforeAll {
            $Script:PSDK_SERVICE = 'blub'
            Mock Invoke-RestMethod -verifiable -parameterFilter { $Uri -eq 'blub/na/rock' -and $OutFile -eq 'TestDrive:a.txt' }

            Invoke-API-Call 'na/rock' TestDrive:a.txt
        }

        It 'calls Invoke-RestMethod with file path' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Clear-Directory' {
    Context 'Directory with subdirectories and files' {
        BeforeAll {
            New-Item -ItemType Directory TestDrive:bla | Out-Null
            New-Item -ItemType Directory TestDrive:bla\a | Out-Null
            New-Item -ItemType Directory TestDrive:bla\b | Out-Null
            New-Item -ItemType File TestDrive:bla\c | Out-Null
            New-Item -ItemType File TestDrive:bla\a\a | Out-Null

            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq '2 archive(s) flushed, freeing 0 MB' }

            Clear-Directory TestDrive:bla
        }

        It 'Cleans the Test-Path file' {
            Test-Path TestDrive:bla | Should -Be $False
        }

        It 'Write info to host' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Resolve-Broadcast' {
    Context 'Cache broadcast message different than new broadcast' {
        BeforeAll {
            Mock-PSDK-Dir
            $Script:PSDK_BROADCAST_PATH = "$Global:PSDK_DIR\broadcast.txt"
            Set-Content $Script:PSDK_BROADCAST_PATH 'Old Broadcast message'
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'New Broadcast message' }

            Resolve-Broadcast list 'New Broadcast message'
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

            Resolve-Broadcast list 'New Broadcast message'
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

            Resolve-Broadcast b 'New Broadcast message'
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

            Resolve-Broadcast broadcast 'New Broadcast message'
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

            Resolve-Broadcast selfupdate 'New Broadcast message'
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

            Resolve-Broadcast flush 'New Broadcast message'
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

Describe 'Initialize-Candidate-Cache' {
    Context 'Candidate cache file does not exists' {
        BeforeAll {
            Mock-PSDK-Dir
            $Script:PSDK_CANDIDATES_PATH = "$Global:PSDK_DIR\candidates.txt"
        }

        It 'throws an error' {
            { Initialize-Candidate-Cache } | Should -Throw
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

            Initialize-Candidate-Cache
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

            Mock Test-Online-Mode -verifiable
            Mock Invoke-API-Call -verifiable -parameterFilter { $Path -eq 'broker/download/sdkman/version/stable' -and $FileTarget -eq "$Global:PSDK_DIR\version.txt" }
            Mock Invoke-API-Call -verifiable -parameterFilter { $Path -eq 'candidates/all' -and $FileTarget -eq "$Global:PSDK_DIR\candidates.txt" }

            Update-Candidates-Cache
        }

        It 'calls the Test-Online-Mode and two API paths' {
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

Describe 'Get-Version-List' {
    Context 'Returns Rest-API-Call response' {

        BeforeAll {
            Mock Get-Current-Candidate-Version { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Installed-Candidate-Version-List { return '1.1.1', '2.2.2', '2.3.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Invoke-API-Call { 'bla' } -parameterFilter { $Path -eq 'candidates/grails/cygwin/versions/list?current=1.1.1&installed=1.1.1,2.2.2,2.3.0' }
        }

        It 'returns bla' {
            Get-Version-List grails | Should -Be 'bla'
            Assert-MockCalled Invoke-API-Call 1
        }
    }

}

Describe 'Get-Online-Candidate-Version-List' {
    Context 'Returns array of possible candidates to install' {
        BeforeAll {
            Mock Get-Current-Candidate-Version { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Installed-Candidate-Version-List { return '1.1.1', '2.2.2', '2.3.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Invoke-API-Call { '1.1.1, 2.3.0, 4.0.0-foo | 5.foo-bla' } -parameterFilter { $Path -eq 'candidates/grails/cygwin/versions/list?current=1.1.1&installed=1.1.1,2.2.2,2.3.0' }
        }

        It 'get an array from the string' {
            Get-Online-Candidate-Version-List grails | Should -Be @('1.1.1', '2.3.0', '4.0.0-foo', '5.foo-bla')
            Assert-MockCalled Invoke-API-Call 1
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
            Mock Test-Online-Mode -verifiable
            $Script:PSDK_SERVICE = 'foobar'
            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            $testFilePath = "$PSScriptRoot\test\grails-1.3.9.zip"

            Mock -CommandName Get-File-From-Url -verifiable -MockWith { Copy-Item $testFilePath "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip" } -ParameterFilter { $Url -eq 'foobar/broker/download/grails/1.3.9/cygwin' -and $TargetFile -eq "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip" }

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
            Mock Get-File-From-Url

            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            New-Item -ItemType Directory $Script:PSDK_ARCHIVES_PATH | Out-Null
            Copy-Item "$PSScriptRoot\test\grails-1.3.9.zip" "$Script:PSDK_ARCHIVES_PATH\grails-1.3.9.zip"

            Install-Remote-Version grails 1.3.9
        }

        It 'does not download the archive again' {
            Assert-MockCalled Get-File-From-Url 0
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
            Mock Get-File-From-Url

            $Script:PSDK_ARCHIVES_PATH = "$Global:PSDK_DIR\archives"
            $Script:PSDK_TEMP_PATH = "$Global:PSDK_DIR\temp"
            New-Item -ItemType Directory $Script:PSDK_ARCHIVES_PATH | Out-Null
            Copy-Item "$PSScriptRoot\test\grails-2.2.2.zip" "$Script:PSDK_ARCHIVES_PATH\grails-2.2.2.zip"
        }

        It 'fails because of no unziped files' {
            { Install-Remote-Version grails 2.2.2 } | Should -Throw
        }

        It 'does not download the archive again' {
            Assert-MockCalled Get-File-From-Url 0
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}
