# posh-sdk - the POwerSHell The Software Development Kit Manager

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/ronnypolley/posh-sdkman/badge)](https://scorecard.dev/viewer/?uri=github.com/ronnypolley/posh-sdkman)

posh-sdk is a clone of the [SDK CLI](https://github.com/sdkman/sdkman-cli). In most aspects its an 1:1 copy of the BASH based version.

For further information about the features of SDKMAN! please the documentation on the [SDKMAN! Project Page](https://sdkman.io).

posh-sdk consumes the REST-API of the offical SDKMAN! CLI and may therefore break if the API will be changed in future.

Please report any bugs and feature request on the [GitHub Issue Tracker](https://github.com/ronnypolley/posh-sdkman/issues).

## ATTENTION - Always offline and selfupdate Issue

Recently the used url for the API endpoint got drop so that the posh-sdk thinks there is always a connection issue. The newest available version uses the new API endpoint but due to the expected connection issue the update has to be done manually.

Please update the posh-sdk client using your favorite method. PsGet users also could use `Update-Module posh-sdk`.

## Differences to the BASH version

- different directory used as default ~\.posh-sdk instead of ~\.sdk -> posh-sdk is not directly able to manage the .sdk-dir of SDKMAN!
- command extension are not supported
- different way to configurate data-dir and auto-anwser
- not all installable candidates are useful currently in Powershell (eg the groovyserv 0.13 package is not usable because there is no client app/script in the package)

## Installation

You have multiple choices for installation of posh-sdk:

Requirements:

- Powershell 3.0+ (included in Windows 8+/Windows Server 2012+, for Windows 7 install Windows Management Framework 3.0)

### With PsGet

1. Execute `Install-Module -Name Posh-SDKMan`
2. Execute `Import-Module Posh-SDKMan`(best add it to your profile.ps1)
3. Execute `sdk help` to get started!

### Via short script (currently not working)

1. Execute `(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ronnypolley/posh-sdkman/main/PSSDKMan/GetPoshSDK.ps1') | iex`
2. Execute `Import-Module posh-sdk`(best add it to your profile.ps1)
3. Execute `sdk help` to get started!

### Classic way

1. Checkout this repository to your Powershell module-directory.
2. Execute `Import-Module posh-sdk`(best add it to your profile.ps1)
3. Execute `sdk help` to get started!

## Update

Newer versions of posh-sdk will notify you about new versions which can be installed by `sdk selfupdate`. If `sdk version` does not show a version of posh-sdk you have to update manually.

### How to get a update of posh-sdk manually ?

How to update depends on how you installed posh-sdk:

#### With PsGet

Update-Module posh-sdk

#### Via short Script

(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ronnypolley/posh-sdkman/main/PSSDKMan/GetPoshSDK.ps1') | iex

#### Classic way

Go to the checkout location and pull the repository.

## Usage

For a general overview of the feature please the [SDKMAN! Project Page](https://sdkman.io) because posh-sdk is designed to work like the original BASH client.

Add `Import-Module posh-sdk` to your powershell profile to be able to use it after each start of Powershell. If you do not know where your profile is located, execute `$Global:profile`.

### Configuration

By default posh-sdk put all the data (inclusive the to be installed executables) into ~/.posh_sdk. You can change the location by setting:

    $Global:PSDK_DIR = <path>

n your profile BEFORE the `Import-Module posh-sdk` line.

Similar to the BASH client you can configure posh-sdk to automatically set new installed versions as default version. You do this by adding:

    $Global:PSDK_AUTO_ANSWER = $true

in your profile.

## Uninstall

If you want to remove posh-sdk you need to perform 3 steps:

1. Remove the `Import-Module posh-sdk` statement from your powershell profile (The path can be found with `PS> $PROFILE`).
2. Remove the `posh-sdk` folder from you powershell modules (Most likely posh-sdk is in the first path of `PS> $env:PSModulePath`).
3. Remove the `~\posh_sdk` folder in your home folder.

If you now restart your powershell instance, posh-sdk is gone.

## Troubleshooting

Q: Error "File xxx cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details."

A: By default, PowerShell restricts execution of all scripts. This is all about security. To "fix" this run PowerShell as Administrator and call

    Set-ExecutionPolicy RemoteSigned

## Running the Pester Tests

All posh-sdk test are written for Pester. Please see its documentation: [Pester](https://github.com/pester/Pester)

To run the tests in Powershell, load the Pester module and run in posh-sdk dir:

    Invoke-Pester
