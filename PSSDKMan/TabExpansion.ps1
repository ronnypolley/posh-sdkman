﻿# Check if function TabExpansion already exists and backup existing version to
# prevent breaking other TabExpansion implementations.
# Taken from posh-git https://github.com/dahlbyk/posh-git/blob/master/GitTabExpansion.ps1#L297
$tabExpansionBackup = 'PoshSDK_DefaultTabExpansion'
if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion $tabExpansionBackup -ErrorAction SilentlyContinue
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) {
        # Execute sdk tab expansion for sdk command
        '^sdk (.*)' { sdkTabExpansion($lastBlock) }
        # Fall back on existing tab expansion
        default { if (Test-Path Function:\$tabExpansionBackup) { & $tabExpansionBackup $line $lastWord } }
    }
}

$Script:PSDK_TAB_COMMANDS = @('install','uninstall','rm','list','use','default','current','version','broadcast','help','offline','selfupdate','flush')
function sdkTabExpansion($lastBlock) {
    if ( !($lastBlock -match '^sdk\s+(?<cmd>\S+)?(?<args> .*)?$') ) {
        return
    }
    $command = $Matches['cmd']
    $arguments = $Matches['args']

    if ( !($arguments) ) {
        # Try to complete the command
        return $Script:PSDK_TAB_COMMANDS | Where-Object { $_.StartsWith($command) }
    }

    $arguments = $arguments.TrimStart()
    # Help add correct parameters
    switch -regex ($command) {
        '^i(nstall)?'    { Search-PSDKTabExpansion-Candidate $command $arguments }
        '^(uninstall|rm)'{ Search-PSDKTabExpansion-Candidate $command $arguments }
        '^(ls|list)'     { Search-PSDKTabExpansion-Candidate $command $arguments }
        '^u(se)?'        { Search-PSDKTabExpansion-Candidate $command $arguments }
        '^d(efault)?'    { Search-PSDKTabExpansion-Candidate $command $arguments }
        '^c(urrent)?'    { Search-PSDKTabExpansion-Candidate $command $arguments }
        '^offline'       { Get-PSDKTabExpansion-Offline $arguments }
        '^flush'         { Get-PSDKTabExpansion-Clear $arguments }
        default          {}
    }
}

function Search-PSDKTabExpansion-Candidate($Command, $LastBlock) {
    if ( !($LastBlock -match "^(?<candidate>\S+)?(?<args> .*)?$") ) {
        return
    }
    $candidate = $Matches['candidate']
    $arguments = $Matches['args']

    Initialize-Candidate-Cache

    if ( !($arguments) ) {
        # Try to complete the command
        return $Script:SDK_CANDIDATES | Where-Object { $_.StartsWith($candidate) }
    }

    if ( !($Script:SDK_CANDIDATES -contains $candidate) ) {
        return
    }

    $arguments = $arguments.TrimStart()
    # Help add correct parameters
    switch -regex ($command) {
        '^i(nstall)?'    { Search-PSDKTabExpansion-Online-Version $candidate $arguments }
        '^(uninstall|rm)'{ Search-PSDKTabExpansion-Version $candidate $arguments }
        '^u(se)?'        { Search-PSDKTabExpansion-Version $candidate $arguments }
        '^d(efault)?'    { Search-PSDKTabExpansion-Version $candidate $arguments }
        default          {}
    }
}

function Search-PSDKTabExpansion-Online-Version ($Candidate, $LastBlock) {
    Get-Online-Candidate-Version-List $Candidate | Where-Object { $_.toLower().Contains($LastBlock) }
}

function Search-PSDKTabExpansion-Version($Candidate, $LastBlock) {
    Get-Installed-Candidate-Version-List $Candidate | Where-Object { $_.StartsWith($LastBlock) }
}

function Get-PSDKTabExpansion-Offline($Arguments) {
    @('enable','disable') | Where-Object { ([string]$_).StartsWith($Arguments) }
}

function Get-PSDKTabExpansion-Clear($Arguments) {
    @('candidates','broadcast','archives','temp') | Where-Object { ([string]$_).StartsWith($Arguments) }
}

Export-ModuleMember TabExpansion
Export-ModuleMember sdkTabExpansion
