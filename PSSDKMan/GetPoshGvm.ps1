<#
	Paragon for the installation script is PsGet
#>

function Install-posh-sdk() {
    $poshGvmZipUrl = 'https://github.com/flofreud/posh-sdk/archive/master.zip'

    $poshGvmPath = Find-Module-Location

    try {
        # create temp dir
        $tempDir = [guid]::NewGuid().ToString()
        $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
        New-Item -ItemType Directory $tempDir | Out-Null

        # download current version
        $poshGvmZip = "$tempDir\posh-sdk-master.zip"
        Write-Output "Downloading posh-sdk from $poshGvmZipUrl"

        $client = (New-Object Net.WebClient)
        $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $client.DownloadFile($poshGvmZipUrl, $poshGvmZip)

        # unzip archive
        $shell = New-Object -com shell.application
        $shell.namespace($tempDir).copyhere($shell.namespace($poshGvmZip).items(), 0x14)

        # check if unzip successfully
        if ( Test-Path "$tempDir\posh-sdk-master" ) {
            if ( !(Test-Path $poshGvmPath) ) {
               New-Item -ItemType Directory $poshGvmPath | Out-Null
            }

            Copy-Item "$tempDir\posh-sdk-master\*" $poshGvmPath -Force -Recurse
            Write-Output "posh-sdk installed!"
            Write-Output "Please see https://github.com/flofreud/posh-sdk#usage for details to get started."
            Write-Warning "Execute 'Import-Module posh-sdk -Force' so changes take effect!"
        } else {
            Write-Warning 'Could not unzip archive containing posh-sdk. Most likely the archive is currupt. Please try to install again.'
        }
    } finally {
        # clear temp dir
        Remove-Item -Recurse -Force $tempDir
    }
}

function Find-Module-Location {
    $moduleDescriptor = Get-Module posh-sdk

    if ( $moduleDescriptor ) {
        return (Get-Item ($moduleDescriptor).Path).Directory.FullName
    } else {
        $modulePaths = @($Env:PSModulePath -split ';')
        # set module path to posh default
        $targetModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
        # if its not use select the first defined
        if ( $modulePaths -inotcontains $targetModulePath  ) {
            $targetModulePath = $modulePaths | Select-Object -Index 0
        }

        return "$targetModulePath\posh-sdk"
    }
}

Install-posh-sdk
