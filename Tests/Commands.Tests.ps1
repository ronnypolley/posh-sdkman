BeforeAll {
    . ..\PSSDKMan\Commands.ps1
    . ..\PSSDKMan\Utils.ps1
    . ..\PSSDKMan\Init.ps1
    . .\TestUtils.ps1
}

Describe 'sdk' {
    Context 'No posh-sdk dir available' {
        BeforeAll {
            $Script:PSDK_FORCE_OFFLINE = $true
            Mock-PSDK-Dir
            Remove-Item $Global:PSDK_DIR -Recurse -Force
            Mock Initialize-Posh-SDK -verifiable
            Mock Initialize-Candidate-Cache -verifiable
            Mock Show-Help
        }

        It 'initalize posh-sdk' {
            sdk
            Assert-VerifiableMock
        }

        It 'prints help' {
            sdk
            Assert-MockCalled Show-Help 1
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'posh-sdk dir available' {
        BeforeAll {
            $Script:PSDK_FORCE_OFFLINE = $true
            Mock-PSDK-Dir
            Mock Initialize-Posh-SDK
            Mock Initialize-Candidate-Cache -verifiable
            Mock Show-Help
        }

        BeforeEach {
            sdk
        }

        It 'initalize posh-sdk' {
            Assert-VerifiableMock
        }

        It 'does not init again' {
            Assert-MockCalled Initialize-Posh-SDK 0
        }

        It 'prints help' {
            Assert-MockCalled Show-Help 1
        }

    }

    Context 'posh-sdk is forced offline' {
        BeforeAll {
            Mock-PSDK-Dir
            Mock Initialize-Candidate-Cache -verifiable
            Mock Test-Available-Broadcast
            Mock Show-Help -verifiable
            $Script:PSDK_FORCE_OFFLINE = $true
        }


        It 'does not load broadcast message from api' {
            sdk
            Assert-MockCalled Test-Available-Broadcast 0
        }

        It 'performs default command actions' {
            sdk
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'posh-sdk offline command called' {
        BeforeAll {
            Mock-PSDK-Dir
            Mock Initialize-Candidate-Cache -verifiable
            Mock Test-Available-Broadcast
            Mock Set-Offline-Mode -verifiable
            $Script:PSDK_FORCE_OFFLINE = $false
        }


        It 'does not load broadcast message from api' {
            sdk offline
            Assert-MockCalled Test-Available-Broadcast 0
        }

        It 'performs offline command actions' {
            sdk offline
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'posh-sdk online and command i called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Install-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.2' -and $InstallPath -eq '\bla' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls install-command' {
            sdk i grails 2.2.2 \bla
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command install called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Install-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.2' -and $InstallPath -eq '' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls install-command' {
            sdk install grails 2.2.2
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command uninstall called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Uninstall-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.2' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls uninstall-command' {
            sdk uninstall grails 2.2.2
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command rm called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Uninstall-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls uninstall-command' {
            sdk rm grails 2.2.1
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command ls called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Candidate-Versions -verifiable -parameterFilter { $Candidate -eq 'grails' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls list-command' {
            sdk ls grails
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command list called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Candidate-Versions -verifiable -parameterFilter { $Candidate -eq 'grails' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls list-command' {
            sdk list grails
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command u called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Use-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls use-command' {
            sdk u grails 2.2.1
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command use called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Use-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls use-command' {
            sdk use grails 2.2.1
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command d called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Set-Default-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls default-command' {
            sdk d grails 2.2.1
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command default called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Set-Default-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '2.2.1' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls default-command' {
            sdk default grails 2.2.1
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command c called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Current-Version -verifiable -parameterFilter { $Candidate -eq 'grails' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls current-command' {
            sdk c grails
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command current called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Current-Version -verifiable -parameterFilter { $Candidate -eq 'grails' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls current-command' {
            sdk current grails
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command v called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Posh-SDK-Version -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls version-command' {
            sdk v
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command version called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Posh-SDK-Version -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls version-command' {
            sdk version
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command b called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Broadcast-Message -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls broadcast-command' {
            sdk b
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command broadcast called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Broadcast-Message -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls broadcast-command' {
            sdk broadcast
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command h called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Help -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls help-command' {
            sdk h
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command help called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Show-Help -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls help-command' {
            sdk help
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command offline called' {
        BeforeAll {
            Mock-Dispatcher-Test -Offline
            Mock Set-Offline-Mode -verifiable -parameterFilter { $Flag -eq 'enable' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls offline-command' {
            sdk offline enable
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command selfupdate called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Invoke-Self-Update -verifiable
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls selfupdate-command' {
            sdk selfupdate
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }

    Context 'posh-sdk online and command flush called' {
        BeforeAll {
            Mock-Dispatcher-Test
            Mock Clear-Cache -verifiable -parameterFilter { $DataType -eq 'version' }
        }


        It 'checks for new broadcast, inits the Candidate-Cache and calls flush-command' {
            sdk flush version
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-Dispatcher-Test
        }
    }
}

Describe 'Install-Candidate-Version' {
    Context 'Remote Version already installed' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { '1.1.1' } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Test-Is-Candidate-Version-Locally-Available { $true } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
        }

        It 'throw an error' {
            { Install-Candidate-Version grails 1.1.1 } | Should -Throw
        }

        It 'process precondition checks' {
            Assert-VerifiableMock
        }
    }

    Context 'Local Version already installed' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { throw 'error' } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Test-Is-Candidate-Version-Locally-Available { $true } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
        }

        It 'throw an error' {
            { Install-Candidate-Version grails 1.1.1 \bla } | Should -Throw
        }

        It 'process precondition checks' {
            Assert-VerifiableMock
        }
    }

    Context 'Local path but version is remote available already installed' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { 1.1.1 } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
        }

        It 'throw an error' {
            { Install-Candidate-Version grails 1.1.1 \bla } | Should -Throw
        }

        It 'process precondition checks' {
            Assert-VerifiableMock
        }
    }

    Context 'Local version installation without defaulting' {
        BeforeAll {
            $Global:backupAutoAnswer = $Global:PSDK_AUTO_ANSWER
            $Global:PSDK_AUTO_ANSWER = $false
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { throw 'error' } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Test-Is-Candidate-Version-Locally-Available { $false } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Install-Local-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' -and $LocalPath -eq '\bla' }
            Mock Read-Host { 'n' }
            Mock Set-Linked-Candidate-Version
            Install-Candidate-Version grails 1.1.1 \bla
        }


        It 'installs the local version' {
            Assert-VerifiableMock
        }

        It "does not set default" {
            Assert-MockCalled Set-Linked-Candidate-Version 0
        }

        AfterAll {
            $Global:PSDK_AUTO_ANSWER = $Global:backupAutoAnswer
        }
    }

    Context 'Local version installation with auto defaulting' {
        BeforeAll {
            $Global:backupAutoAnswer = $Global:PSDK_AUTO_ANSWER
            $Global:PSDK_AUTO_ANSWER = $true
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { throw 'error' } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Test-Is-Candidate-Version-Locally-Available { $false } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Install-Local-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' -and $LocalPath -eq '\bla' }
            Mock Set-Linked-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Write-Output -verifiable

            Install-Candidate-Version grails 1.1.1 \bla
        }

        It 'installs the local version' {
            Assert-VerifiableMock
        }

        AfterAll {
            $Global:PSDK_AUTO_ANSWER = $Global:backupAutoAnswer
        }
    }

    Context 'Remote version installation with prompt defaulting' {
        BeforeAll {
            $Global:backupAutoAnswer = $Global:PSDK_AUTO_ANSWER
            $Global:PSDK_AUTO_ANSWER = $false
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Candidate-Version-Available { '1.1.1' } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Test-Is-Candidate-Version-Locally-Available { $false } -verifiable { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Install-Remote-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Read-Host { 'y' }
            Mock Set-Linked-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Write-Output -verifiable

            Install-Candidate-Version grails 1.1.1
        }

        It 'installs the local version' {
            Assert-VerifiableMock
        }

        AfterAll {
            $Global:PSDK_AUTO_ANSWER = $Global:backupAutoAnswer
        }
    }
}

Describe 'Uninstall-Candidate-Version' {
    Context 'No version is provided' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
        }

        It 'throws an error' {
            { Uninstall-Candidate-Version grails } | Should -Throw
        }
    }

    Context 'To be uninstalled version is not installed' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Is-Candidate-Version-Locally-Available { $false } -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '24.3' }
        }

        It 'throws an error' {
            { Uninstall-Candidate-Version grails 24.3 } | Should -Throw
        }

        It 'checks candidate' {
            Assert-VerifiableMock
        }
    }

    Context 'To be uninstalled Version is current version' {
        BeforeAll {
            Mock-PSDK-Dir
        }

        BeforeEach {
            if ( ! (Test-Path "$Global:PSDK_DIR\grails\24.3") ) {
                New-Item -ItemType Directory "$Global:PSDK_DIR\grails\24.3" | Out-Null
            }
            Set-Linked-Candidate-Version grails 24.3
        }

        It 'finds current-junction defined' {
            Test-Path "$Global:PSDK_DIR\grails\current" | Should -Be $true
        }

        Context "deletion testing" {
            BeforeAll {
                Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
                Mock Test-Is-Candidate-Version-Locally-Available { $true } -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '24.3' }
                Mock Get-Current-Candidate-Version { '24.3' } -verifiable -parameterFilter { $Candidate -eq 'grails' }
                Mock Write-Output -verifiable
            }

            BeforeEach {
                Uninstall-Candidate-Version grails 24.3
            }

            It 'delete the current-junction' {
                Test-Path "$Global:PSDK_DIR\grails\current" | Should -Be $false
            }

            It 'delete the version' {
                Test-Path "$Global:PSDK_DIR\grails\24.3" | Should -Be $false
            }

            It "checks different preconditions correctly" {
                Assert-VerifiableMock
            }
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }

    Context 'To be uninstalled version is installed' {
        BeforeAll {
            Mock-PSDK-Dir
            New-Item -ItemType Directory "$Global:PSDK_DIR\grails\24.3" | Out-Null

            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Test-Is-Candidate-Version-Locally-Available { $true } -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '24.3' }
            Mock Get-Current-Candidate-Version { $null } -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable
            Uninstall-Candidate-Version grails 24.3
        }

        It 'delete the version' {
            Test-Path "$Global:PSDK_DIR\grails\24.3" | Should -Be $false
        }

        It "checks different preconditions correctly" {
            Assert-VerifiableMock
        }

        AfterAll {
            Reset-PSDK-Dir
        }
    }
}

Describe 'Show-Candidate-Versions' {
    Context 'if in online mode' {
        BeforeAll {
            Mock Get-Online-Mode { return $true }
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Version-List -verifiable -parameterFilter { $Candidate -eq 'grails' }

            Show-Candidate-Versions grails
        }

        It 'write the version list retrieved from api' {
            Assert-VerifiableMock
        }
    }

    Context 'If in offline mode' {
        BeforeAll {
            Mock Get-Online-Mode { return $false }
            Mock Test-Candidate-Present -verifiable -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Offline-Version-List -verifiable -parameterFilter { $Candidate -eq 'grails' }

            Show-Candidate-Versions grails
        }

        It 'write the version list based on local file structure' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Use-Candidate-Version' {
    Context 'If new use version is already used' {
        BeforeAll {
            Mock Test-Candidate-Version-Available { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Get-Env-Candidate-Version { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable
            Mock Test-Candidate-Version-Locally-Available
        }

        BeforeEach {
            Use-Candidate-Version grails 1.1.1
        }

        It 'changes nothing' {
            Assert-VerifiableMock
        }

        It 'does not test candidate version' {
            Assert-MockCalled Test-Candidate-Version-Locally-Available 0
        }
    }

    Context 'If setting a different version as the current version to use' {
        BeforeAll {
            Mock Test-Candidate-Version-Available { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Get-Env-Candidate-Version { '1.1.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable
            Mock Test-Candidate-Version-Locally-Available -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Set-Env-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
        }

        BeforeEach {
            Use-Candidate-Version grails 1.1.1
        }

        It 'perform the changes' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Set-Default-Version' {
    Context 'If new default is already default' {
        BeforeAll {
            Mock Test-Candidate-Version-Available { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Get-Current-Candidate-Version { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable
            Mock Test-Candidate-Version-Locally-Available
        }

        BeforeEach {
            Set-Default-Version grails 1.1.1
        }

        It 'changes nothing' {
            Assert-VerifiableMock
        }

        It 'does not test candidate version' {
            Assert-MockCalled Test-Candidate-Version-Locally-Available 0
        }
    }

    Context 'If setting a new default' {
        BeforeAll {
            Mock Test-Candidate-Version-Available { '1.1.1' } -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Get-Current-Candidate-Version { '1.1.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable
            Mock Test-Candidate-Version-Locally-Available -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
            Mock Set-Linked-Candidate-Version -verifiable -parameterFilter { $Candidate -eq 'grails' -and $Version -eq '1.1.1' }
        }

        BeforeEach {
            Set-Default-Version grails 1.1.1
        }

        It 'perform the changes' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Show-Current-Version' {
    Context 'If called without candidate' {
        BeforeAll {
            $Script:SDK_CANDIDATES = @('grails', 'groovy', 'bla')
            Mock Get-Env-Candidate-Version { '1.1.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Get-Env-Candidate-Version { '2.1.0' } -parameterFilter { $Candidate -eq 'groovy' }
            Mock Get-Env-Candidate-Version { '0.1.0' } -parameterFilter { $Candidate -eq 'bla' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'Using:' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'grails: 1.1.0' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'groovy: 2.1.0' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'bla: 0.1.0' }
        }

        BeforeEach {
            Show-Current-Version
        }

        It 'write the version for all currently used candidates' {
            Assert-VerifiableMock
        }
    }

    Context 'If called with specifiv candidate and version available' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable
            Mock Get-Env-Candidate-Version { '1.1.0' } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'Using grails version 1.1.0' }
        }

        BeforeEach {
            Show-Current-Version grails
        }

        It 'write version info' {
            Assert-VerifiableMock
        }
    }

    Context 'If called with specifiv candidate and no version available' {
        BeforeAll {
            Mock Test-Candidate-Present -verifiable
            Mock Get-Env-Candidate-Version { $null } -parameterFilter { $Candidate -eq 'grails' }
            Mock Write-Output -verifiable -parameterFilter { $InputObject -eq 'Not using any version of grails' }
        }

        BeforeEach {
            Show-Current-Version grails
        }

        It 'write no version is available' {
            Assert-VerifiableMock
        }
    }
}

Describe 'Show-Posh-SDK-Version' {
    Context 'When called' {
        BeforeAll {
            Mock Get-SDKMAN-API-Version -verifiable
            Mock Get-Posh-SDK-Version -verifiable
            Mock Write-Output -verifiable
        }


        It 'write the version message to output' {
            Show-Posh-SDK-Version
            Assert-VerifiableMock
        }
    }
}

Describe 'Show-Broadcast-Message' {
    Context 'When called' {
        BeforeAll {
            $Script:PSDK_BROADCAST_PATH = 'broadcast'
            Mock Get-Content { 'broadcast' } -verifiable -parameterFilter { $Path -eq 'broadcast' }
            Mock Write-Output -verifiable
        }


        It 'Write broadcast message to output' {
            Show-Broadcast-Message
            Assert-VerifiableMock
        }
    }
}

Describe 'Set-Offline-Mode' {
    Context 'If called with invalid flag' {
        It 'throws an error' {
            { Set-Offline-Mode invalid } | Should -Throw
        }
    }

    Context 'If called with enable flag' {
        BeforeAll {
            $Script:PSDK_FORCE_OFFLINE = $false
            Mock Write-Output -verifiable
        }

        BeforeEach {
            Set-Offline-Mode enable
        }

        It "set offline mode" {
            $Script:PSDK_FORCE_OFFLINE | Should -Be $true
        }

        It "writes info to output" {
            Assert-VerifiableMock
        }
    }

    Context 'if called with disable flag' {
        BeforeAll {
            $Script:PSDK_ONLINE = $false
            $Script:PSDK_FORCE_OFFLINE = $true
            Mock Write-Output -verifiable
        }

        BeforeEach {
            Set-Offline-Mode disable
        }

        It "deactivate offline mode" {
            $Script:PSDK_FORCE_OFFLINE | Should -Be $false
        }

        It "set sdk to online" {
            $Script:PSDK_ONLINE | Should -Be $true
        }

        It "writes info to output" {
            Assert-VerifiableMock
        }
    }
}

Describe 'Clear-Cache' {
    Context 'Try to delete existing candidates cache' {
        BeforeAll {
            $Script:PSDK_CANDIDATES_PATH = 'test'
            Mock Test-Path { $true } -parameterFilter { $Path -eq 'test' }
            Mock Remove-Item -verifiable -parameterFilter { $Path -eq 'test' }
            Mock Write-Output -verifiable
        }


        It 'deletes the file and writes flush message' {
            Clear-Cache candidates
            Assert-VerifiableMock
        }
    }

    Context 'Try to delete non-existing candidates cache' {
        BeforeAll {
            $Script:PSDK_CANDIDATES_PATH = 'test2'
            Mock Test-Path { $false } -parameterFilter { $Path -eq 'test2' }
            Mock Write-Warning -verifiable
        }


        It 'writes warning about non existing file' {
            Clear-Cache candidates
            Assert-VerifiableMock
        }
    }

    Context 'Try to delete existing broadcast cache' {
        BeforeAll {
            $Script:PSDK_BROADCAST_PATH = 'test'
            Mock Test-Path { $true } -parameterFilter { $Path -eq 'test' }
            Mock Remove-Item -verifiable -parameterFilter { $Path -eq 'test' }
            Mock Write-Output -verifiable
        }


        It 'deletes the file and writes flush message' {
            Clear-Cache broadcast
            Assert-VerifiableMock
        }
    }

    Context 'Try to delete non-existing broadcast cache' {
        BeforeAll {
            $Script:PSDK_BROADCAST_PATH = 'test2'
            Mock Test-Path { $false } -parameterFilter { $Path -eq 'test2' }
            Mock Write-Warning -verifiable
        }


        It 'writes warning about non existing file' {
            Clear-Cache broadcast
            Assert-VerifiableMock
        }
    }

    Context 'Try to delete existing version cache' {
        BeforeAll {
            $Script:PSDK_API_VERSION_PATH = 'test'
            Mock Test-Path { $true } -parameterFilter { $Path -eq 'test' }
            Mock Remove-Item -verifiable -parameterFilter { $Path -eq 'test' }
            Mock Write-Output -verifiable
        }


        It 'deletes the file and writes flush message' {
            Clear-Cache version
            Assert-VerifiableMock
        }
    }

    Context 'Try to delete non-existing version cache' {
        BeforeAll {
            $Script:PSDK_API_VERSION_PATH = 'test2'
            Mock Test-Path { $false } -parameterFilter { $Path -eq 'test2' }
            Mock Write-Warning -verifiable
        }


        It 'writes warning about non existing file' {
            Clear-Cache version
            Assert-VerifiableMock
        }
    }

    Context 'Cleanup archives directory' {
        BeforeAll {
            $Script:PSDK_ARCHIVES_PATH = 'archives'
            Mock Clear-Directory -verifiable -parameterFilter { $Path -eq 'archives' }
        }


        It 'cleanup archives directory' {
            Clear-Cache archives
            Assert-VerifiableMock
        }
    }

    Context 'Cleanup temp directory' {
        BeforeAll {
            $Script:PSDK_TEMP_PATH = 'temp'
            Mock Clear-Directory -verifiable -parameterFilter { $Path -eq 'temp' }
        }


        It 'cleanup temp directory' {
            Clear-Cache temp
            Assert-VerifiableMock
        }
    }

    Context 'Cleanup tmp directory' {
        BeforeAll {
            $Script:PSDK_TEMP_PATH = 'temp'
            Mock Clear-Directory -verifiable -parameterFilter { $Path -eq 'temp' }
        }

        BeforeEach {
            Clear-Cache tmp
        }

        It 'cleanup temp directory' {
            Assert-VerifiableMock
        }
    }

    Context 'flush invalid parameter' {
        It 'throws an error' {
            { Clear-Cache invalid } | Should -Throw
        }
    }
}

Describe 'Show-Help' {
    Context 'If Show-Help is called' {
        BeforeAll {
            Mock Write-Output -verifiable
        }


        It 'write the help to the output' {
            Show-Help
            Assert-VerifiableMock
        }
    }
}

