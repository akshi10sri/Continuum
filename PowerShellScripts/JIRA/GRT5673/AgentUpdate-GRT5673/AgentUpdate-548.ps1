<#
   .SYNOPSIS
       This script updates DPMA and MSMA Agent if version is below 5.4.8.
       Supported Operating system - Windows Server 2008 R2/Windows 7 and above.

   .NOTES
         Version:        1.0
         Author:         GRT
         Creation Date:  29/11/2019
         Purpose/Change: Initial script development
#>

if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if ($myInvocation.Line) {
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }
    else {
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
    exit $lastexitcode
}  

#region Functions

function Download-FromURL ($URL, $LocalFilePath) {
    try {
        #Write-Host "Downloading: $URL"
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($URL, $LocalFilePath)
        if (-not(Test-Path $LocalFilePath)) { Write-Output "Download Failed" }
    }
    catch {
        Write-output "Download Failed"
        exit
    }
}

#endregion Functions

#region Main

$ErrorActionPreference = 'Stop'
$32bit = 'HKLM:\SOFTWARE\SAAZOD\'
$64bit = 'HKLM:\SOFTWARE\Wow6432Node\SAAZOD\'

try {

    if(!([System.Environment]::OSVersion.Version -ge [system.version]'6.1')){
        Write-Output "This script only supports Windows Server 2008 R2\Windows 7 and above."
        exit
    }


    # Identify Agent type is MSMA or DPMA by checking registry key    
    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        $registry = $64bit
    }
    else {
        $registry = $32bit
    }
    $type = Get-ItemProperty -Path $registry -Name 'Type' -ErrorAction SilentlyContinue | ForEach-Object { $_.Type }

    #  Check the version
    $version = Get-ItemProperty -Path $registry -Name 'DisplayVersion' -ErrorAction SilentlyContinue | ForEach-Object { $_.DisplayVersion }

    $requiredversion = [System.Version] '5.4.8'
    if ([System.Version] $version -ge $requiredversion) {
        Write-Output "No Action needed Agent is up-to date"
    }
    else {
        # Download
        $Package = switch($type){
            'DPMA' { 'DPMAPatch.exe' }
            'MSMA' { 'MSMAPatch.exe' }
        }

        $URL = "Http://update.itsupport247.net/agtupdt/$Package"
        $PackageLocalPath = Join-Path $env:TEMP "$Package"
        Download-FromURL -URL $URL -LocalFilePath $PackageLocalPath

        # Execute
        Start-Process -FilePath $PackageLocalPath -ArgumentList '/S' -Wait

        # Verify Agent version
        $newversion = Get-ItemProperty -Path $registry -Name 'DisplayVersion' -ErrorAction SilentlyContinue | ForEach-Object { $_.DisplayVersion }
        if($newversion -eq '5.4.8'){
            Write-Output "Agent Updated"
            Remove-Item -Path $PackageLocalPath -Force -EA SilentlyContinue
        }
        else{
            Write-Output "Installation failed. Agent version: $newversion"
            Remove-Item -Path $PackageLocalPath -Force -EA SilentlyContinue
        }
    }    
}
catch {
    Write-Output $_.exception.message
}
#endregion Main