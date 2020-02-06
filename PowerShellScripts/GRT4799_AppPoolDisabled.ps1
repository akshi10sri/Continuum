<#
.Synopsis
   GRT- 4805 Application pool is being automatically disabled due to series of failures
.DESCRIPTION
    Script will check for the presence of event id 5002 in the System with source WAS and remediate the application pool crash if necessary.
.PARAMETERS
    Checkbox for user to toggle value of LoadUserProfile
    $LoadUserProfile = $false 

    Checkbox for user to toggle value of Enable32BitAppOnWin64
    $Enable32BitAppOnWin64

    Checkbox for user to toggle value of RapidFailProtection
    $RapidFailProtection

    Checkbox for user if they want to assign permissions of List Folder/ReadData and Delete on TEMP folder for NT AUTHORITY\NETWORK SERVICE and application pool user
    $permission

    Checkbox for user to change value of StartMode of application pool to True/AlwaysRunning
    $startmode

    #Checkbox for user to start application pool and browse its site
    $start

[bool]$LoadUserProfile = $true 
[bool]$Enable32BitAppOnWin64 = $true
[bool]$RapidFailProtection = $true
[bool]$permission = $false
[bool]$startmode = $false
[bool]$start = $true
[string]$poolname = ''
.LastModified
    By          : Akshi Srivastava
    On          : 03-Sep-2019
    Contact     : akshi.srivastava@continuum.net
    version     : 1.5
#>

if ($LoadUserProfile -ne $true) {
    $LoadUserProfile = $false
}
if ($Enable32BitAppOnWin64 -ne $true) {
    $Enable32BitAppOnWin64 = $false
}
if ($RapidFailProtection -ne $true) {
    $RapidFailProtection = $false
}
if ($permission -ne $true) {
    $permission = $false
}
if ($startmode -ne $true) {
    $startmode = $false
}
if ($start -ne $true) {
    $start = $false
}

[string]$poolname = 'SBS Sharepoint AppPool'

#Check if event source Microsoft-Windows-WAS exists
$WAS_Source = 'Microsoft-Windows-WAS'
   
   
#***********************************************************************************************
# OS Architecture Check
#***********************************************************************************************
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    #write-warning "Excecuting the script under 64 bit powershell"
    if ($myInvocation.Line) {
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }
    else {
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
    exit $lastexitcode
}
   
   
#***********************************************************************************************
#OS Version and Powershell Version comparison on the machine.
#***********************************************************************************************
try {
    [double]$OSVersion = [Environment]::OSVersion.Version.ToString(2)
    If (($osversion -lt '6.1') -or ($PSVersionTable.PSVersion.Major -lt '2')) {
        Write-Output "Prerequisites to run the script is not valid, Hence script exceution will be stopped"
        $OS = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).ProductName
        if ($Null -ne $OS) {
            Write-Output "[MSG] : Operating System : $OS "
        }
        EXIT
    }
}
catch {
    Write-Output "[ERROR] : $_.Exception.Message"
    EXIT
}
   
$ByPassCertificateErrors = @"
   using System.Net;
   using System.Security.Cryptography.X509Certificates;
   public class TrustAllCertsPolicy : ICertificatePolicy {
   public bool CheckValidationResult(
   ServicePoint srvPoint, X509Certificate certificate,
   WebRequest request, int certificateProblem) {
   return true;
   }
   }
"@
$info = $false  #default value - if true then show status of all application pools   
try {
    $Event5002 = Get-WinEvent -FilterHashtable @{ LogName = "System" ; ID = 5002 ; ProviderName = $WAS_Source } -ErrorAction Stop | Select-Object -First 1
    $event_msg = $Event5002.Message
    if ($event_msg) {
        $Matches = $null    
        if ($event_msg -match "Application pool '(.*?)'") {
            #Get the Application Pool name from Event ID 5002
            $ApplicationPoolName = $Matches[1]
        }
    }
    else {
        Write-Output "[MSG] : Message not found in event id 5002"
        $info = $true
    }
    Write-Output "[MSG] : Event Details as below"
    Write-Output "--------------------------------"
    Write-Output $Event5002 | Format-List
    Write-Output "--------------------------------`n"
}
catch [System.Security.SecurityException] {
   
    Write-Output "[ERROR] : Access Denied"
    $info = $true
    
}
catch {
    if ($_.Exception.Message -like "*not found*" ) {
        Write-Output "[ERROR] : Could not find the source $WAS_Source."
    }
    else {
        Write-Output "[ERROR] : $($_.Exception.Message)"
    }
    #Exit
    $info = $true
    
}   
#import WebAdminstration Module
try {
    Import-Module webadministration -ErrorAction Stop
    $ImportWebAdminmodule = $true 
}
catch {
    Write-Output "[ERROR] : $($_.Exception.Message)"
    Exit
}
   
Clear-Host
#Logic starts here
if ($ImportWebAdminmodule -eq $true) {

    if ($info) {
        try {
            Write-Output "`nSHAREPOINT APPLICATION POOLS DETAILS ARE:"
            Get-ChildItem IIS:\AppPools -ErrorAction Stop | Select-Object name, State | Format-List
        }
        Catch {
            Write-Output "`n[ERROR] : Unable to get details of all application pools[ $($_.Exception.Message) ]"
        }
    }

    Function Troubleshoot {
        param (
        [Parameter(Mandatory=$True)]
        [string]$Name
        )

        try {
            $AppPool = Get-ChildItem IIS:\AppPools -ErrorAction Stop | Where-Object { $_.Name -eq $Name }    
        }
        catch {
            $errormsg = "`n[ERROR] : $($_.Exception.Message)"
            #Exit
        }
        if ($AppPool) {
            
            if ($($AppPool.State) -eq "Started") {
                Write-Output "[MSG] : AppPool '$($AppPool.Name)' is already started. Nothing to troubleshoot."
            }
            elseif ($($AppPool.State) -eq "Stopped") {
                Write-Output "`n[MSG] : Application Pool $($AppPool.name) is STOPPED"
                try {
                    $AppPoolProperties = Get-ItemProperty "IIS:\AppPools\$($AppPool.Name)" -ErrorAction Stop

                    $load = $AppPoolProperties.ProcessModel.LoadUserProfile
                    $enable32bit = $AppPoolProperties.enable32BitAppOnWin64
                    $rapid = $AppPoolProperties.failure.rapidFailProtection
                    $user = $AppPoolProperties.processModel.userName
                    $mode = $AppPoolProperties.autoStart
                    Write-Output "`nLoad User Profile                  : $load"
                    Write-Output "`nEnable 32 Bit App in Win64         : $enable32bit"
                    Write-Output "`nRapid Fail Protection              : $rapid"
                    Write-Output "`nStart Mode                         : $mode"
                    if (-not ([string]::IsNullOrEmpty($user))) {
                        Write-Output "`nApplication Pool User          : $user"    
                    }
                    else {
                        Write-Output "`nApplication Pool Identity Type : $($AppPool.processModel.identityType)" 
                    }
                    try {
                        $SystemTemp = [System.Environment]::GetEnvironmentVariable('Temp', 'Machine')
                        Write-Output "`nPERMISSIONS ON $SystemTemp FOLDER : "
                        (get-acl $SystemTemp -ErrorAction Stop).access | Format-List IdentityReference, FileSystemRights 
                    }
                    catch {
                        Write-Output "[ERROR] : Failed to get permissions of $SystemTemp folder($($_.Exception.Message))"
                    }    

                    #TROUBLESHOOTING PART
                    if (($LoadUserProfile -eq $true) -or ($startmode -eq $true) -or ($Enable32BitAppOnWin64 -eq $true) -or ($RapidFailProtection -eq $true) -or ($start -eq $true) -or ($permission -eq $true)) {
                       
                        Write-Output "`n`nUser chooses to do troubleshooting on this issue"
                        Write-Output "------------------------------------------------"
                        #Get backup of IIS
                        try {
                            Write-Output "`nTaking backup of IIS.."
                            Backup-WebConfiguration -Name "NOC_$(Get-Date -Format dd-MMM-yyyy-hh-mm-ss)" -ErrorAction Stop | Out-Null
                            Write-Output "`nBackup completed"
                        }
                        catch {
                           
                            Write-Output "`nUnexpected error occured while taking backup of web configuration.Error: $($_.Exception.Message)"
                            EXIT
                        }
                        if ($LoadUserProfile -eq $true) {
                            Write-Output "`n[MSG] : Setting LoadUserProfile Value..."
                            if ($load -eq $true) {
                                #Write-Output "[MSG] : LoadUserProfile is already set to TRUE"
                                if (-not ([string]::IsNullOrEmpty($user))) {
                                    try {
                                        #Set-ItemProperty "IIS:\AppPools\$($AppPool.Name)" -Name ProcessModel.LoadUserProfile -Value $true -ErrorAction Stop
                                        $AppPool.processModel.loadUserProfile = 'false'
                                        $AppPool | Set-Item
                                        Write-Output "[MSG] : LoadUserProfile set to FALSE"    
                                    }
                                    catch {
                                        Write-Output "[ERROR] : $($_.Exception.Message)"
                                    }
                                }
                                else {
                                    if ($($AppPool.processModel.identityType) -ne 'ApplicationPoolIdentity') {
                                
                                        try {
                                            $AppPool.processModel.loadUserProfile = 'false'
                                            $AppPool | Set-Item
                                            Write-Output "[MSG] : LoadUserProfile set to FALSE"    
                                        }
                                        catch {
                                            Write-Output "[ERROR] : $($_.Exception.Message)"
                                        }
                                    }
                                    else {
                                        Write-Output "[MSG] : 'ApplicationPoolIdentity' found for application pool $($AppPool.Name). Hence , not making any changes for this property"
                                    }
                                }
                            }
                            else {
                                if (-not ([string]::IsNullOrEmpty($user))) {
                                    try {
                                        #Set-ItemProperty "IIS:\AppPools\$($AppPool.Name)" -Name ProcessModel.LoadUserProfile -Value $true -ErrorAction Stop
                                        $AppPool.processModel.loadUserProfile = 'true'
                                        $AppPool | Set-Item
                                        Write-Output "[MSG] : LoadUserProfile set to TRUE"    
                                    }
                                    catch {
                                        Write-Output "[ERROR] : $($_.Exception.Message)"
                                    }
                                }
                                else {
                                    if ($($AppPool.processModel.identityType) -ne 'ApplicationPoolIdentity') {
                                
                                        try {
                                            $AppPool.processModel.loadUserProfile = 'true'
                                            $AppPool | Set-Item
                                            Write-Output "[MSG] : LoadUserProfile set to TRUE"    
                                        }
                                        catch {
                                            Write-Output "[ERROR] : $($_.Exception.Message)"
                                        }
                                    }
                                    else {
                                        Write-Output "[MSG] : 'ApplicationPoolIdentity' found for application pool $($AppPool.Name). Hence , not making any changes for this property"
                                    }
                                }
                            }
                           
                        }

                        if ($Enable32BitAppOnWin64 -eq $true) {
                            Write-Output "`n[MSG] : Setting Enable 32bit on win64 Value..."
                            if ($enable32bit -eq $false) {
                                #Write-Output "[MSG] : Enable 32Bit App on Win64 is already set to FALSE"
                                try {
                                    #Set-ItemProperty "IIS:\AppPools\$($AppPool.Name)" -Name "enable32BitAppOnWin64" -Value $false -ErrorAction Stop
                                    $AppPool.enable32BitAppOnWin64 = 'true'
                                    $AppPool | Set-Item
                                    Write-Output "[MSG] : Enable 32Bit App on Win64 is set to TRUE"    
                                }
                                catch {
                                    Write-Output "[ERROR] : $($_.Exception.Message)"
                                }
                            }
                            else {
                                try {
                                    #Set-ItemProperty "IIS:\AppPools\$($AppPool.Name)" -Name "enable32BitAppOnWin64" -Value $false -ErrorAction Stop
                                    $AppPool.enable32BitAppOnWin64 = 'false'
                                    $AppPool | Set-Item
                                    Write-Output "[MSG] : Enable 32Bit App on Win64 is set to FALSE"    
                                }
                                catch {
                                    Write-Output "[ERROR] : $($_.Exception.Message)"
                                }
                            }
                        }

                        if ($RapidFailProtection -eq $true) {
                            Write-Output "`n[MSG] : Setting Rapid Fail Protection Value..."
                            if ($rapid -eq $false) {
                                #Write-Output "[MSG] : Rapid Fail Protection is already set to FALSE"
                                try {
                                    #Set-ItemProperty "IIS:\apppools\$($AppPool.Name)" -name Failure.RapidFailProtection -Value $false -ErrorAction Stop
                                    $AppPool.Failure.RapidFailProtection = 'true'
                                    $AppPool | Set-Item
                                    Write-Output "[MSG] : Rapid Fail Protection is set to TRUE"    
                                }
                                catch {
                                    Write-Output "[ERROR] : $($_.Exception.Message)"
                                }
                            }
                            else {
                                try {
                                    #Set-ItemProperty "IIS:\apppools\$($AppPool.Name)" -name Failure.RapidFailProtection -Value $false -ErrorAction Stop
                                    $AppPool.Failure.RapidFailProtection = 'false'
                                    $AppPool | Set-Item
                                    Write-Output "[MSG] : Rapid Fail Protection is set to FALSE"    
                                }
                                catch {
                                    Write-Output "[ERROR] : $($_.Exception.Message)"
                                }
                            }
                        }

                        if ($permission -eq $true) {
                            Write-Output "`n[MSG] : GRANTING PERMISSIONS ON TEMP FOLDER..."
                            #get location of TEMP folder
                            $SystemTemp = [System.Environment]::GetEnvironmentVariable('Temp', 'Machine')
                   
                            #granting permission for NT AUTHORITY\NETWORK SERVICE
                            try {
                                Write-Output "`nGranting permissions for 'NT AUTHORITY\NETWORK SERVICE' on TEMP folder"
                                takeown /f ("$SystemTemp") /a | Out-Null
                                if ($? -eq $true) {
                                    ICACLS ("$SystemTemp") /grant ("NT AUTHORITY\NETWORK SERVICE" + ':(OI)(CI)RD') | Out-Null
                                    ICACLS ("$SystemTemp") /grant ("NT AUTHORITY\NETWORK SERVICE" + ':(OI)(CI)D') | Out-Null
                                    Write-Output "[MSG] : List Folder/Read Data & Delete permissions granted"
                                }
                                else {
                                    Write-Output "`n[MSG] : Unable to grant permission on TEMP folder"
                                }
                            }
                            catch {
                                Write-Output "`n[ERROR] : Unable to grant permission to 'NT AUTHORITY\NETWORK SERVICE' account($($_.Exception.Message))"
                            }

                            #granting permission for $user
                            try {
                                if (-not ([string]::IsNullOrEmpty($user))) {
                                    Write-Output "`nGranting permissions for $user on TEMP folder"
                                    takeown /f ("$SystemTemp") /a | Out-Null
                                    if ($? -eq $true) {
                                        ICACLS ("$SystemTemp") /grant ("$user" + ':(OI)(CI)RD') | Out-Null
                                        ICACLS ("$SystemTemp") /grant ("$user" + ':(OI)(CI)D') | Out-Null
                                        Write-Output "[MSG] : List Folder/Read Data & Delete permissions granted"
                                    }
                                    else {
                                        Write-Output "`n[MSG] : Unable to grant permission on TEMP folder"
                                    }
                                }
                                else {
                                    Write-Output "[MSG] : User doesn't exist for '$($AppPool.Name)' application pool"
                                }
                            }
                            catch {
                                Write-Output "`n[ERROR] : Unable to grant permission $($_.Exception.Message))"
                            }
                        }

                        #change autostart mode of application pool to True
                        if ($startmode -eq $true) {
                            Write-Output "`n[MSG] : Setting AutoStart to TRUE..."
                            if ($mode -eq $true) {
                                Write-Output "[MSG] : AutoStart is already set to TRUE"
                            }
                            else {
                                try {
                                    $iisInfo = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\InetStp\ -ErrorAction Stop
                                    $version = [decimal]"$($iisInfo.MajorVersion).$($iisInfo.MinorVersion)"
                                }
                                catch {
                                    Write-Output "[ERROR] : $($_.Exception.Message)" 
                                }
                                if ($null -ne $version) {
                                    if ($version -le 7.5) {
                                        try {
                                            $AppPool.autoStart = 'true'
                                            $AppPool | Set-Item
                                            Write-Output "[MSG] : AutoStart is set to TRUE" 
                                        }
                                        catch {
                                            Write-Output "[ERROR] : $($_.Exception.Message)"
                                        }
                                    }
                                    else {
                                        try {
                                            $AppPool.autoStart = 'true'
                                            $AppPool.startmode = 'alwaysrunning'
                                            $AppPool | Set-Item
                                            Write-Output "[MSG] : AutoStart is set to TRUE" 
                                        }
                                        catch {
                                            Write-Output "[ERROR] : $($_.Exception.Message)"
                                        }
                                    }  
                                }
                                else {
                                    Write-Output "[ERROR] : Unable to get IIS Version. Not setting this property." 
                                }
                               
                            }
                        }

                        #start application pool
                        if ($start -eq $true) {
                            Write-Output "`n[MSG] : Attempting to start AppPool $($AppPool.name)..."
                            try {
                                Start-WebAppPool -Name $AppPool.Name -ErrorAction Stop
                                $state = Get-ChildItem IIS:\AppPools -ErrorAction Stop | Where-Object { $_.Name -eq $Name }
                                if ($state.State -eq "Started") {
                                    Write-Output " AppPool '$($AppPool.Name)' Started."

                                    #Browse site of application pool
                                    try {

                                        $site = (Get-Website -ErrorAction Stop | Where-Object { $_.applicationpool -eq $($AppPool.Name) }).name
                                        if ($site) {
                                            if ($site.Count -gt 1) {
                                                $web = $site[0]
                                                $Response = Get-WebURL "IIS:\Sites\$web" -ErrorAction SilentlyContinue
                                                $ResponseURI = $Response.ResponseUri
                                            }
                                            else {
                                                $Response = Get-WebURL "IIS:\Sites\$site" -ErrorAction SilentlyContinue
                                                $ResponseURI = $Response.ResponseUri
                                            }
                                            if (-not ([string]::IsNullOrEmpty($ResponseURI))) {
                                                if ($ResponseURI -match "(https?://.*?)/") {
                                                    $WebUrl = $Matches[1]
                                                }
                                                if ($null -ne $WebUrl) {
                                                    #check for url availability
                                                    try {
                                                        Add-Type $ByPassCertificateErrors -ErrorAction Stop
                                                        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
                                                        $certificate = $true
                                                    }
                                                    catch {
                                                        Write-Output "[ERROR] : $($_.Exception.Message)"
                                                        $certificate = $false
                                                    }
                                                    if ($certificate) {
                                                        try {
                                                            $HTTP_Request = [System.Net.WebRequest]::Create($WebUrl)
                                                            $HTTP_Response = $HTTP_Request.GetResponse()
                                                            $HTTP_Status = [int]$HTTP_Response.StatusCode
                                                            if ($null -ne $HTTP_Status) {
                                                                If ($HTTP_Status -eq 200) {
                                                                    Write-Output "[MSG] : Site of this app pool is OK! Issue resolved"
                                                                }
                                                                elseif ($HTTP_Status -eq 503) {
                                                                    Write-Output "[MSG] : The Site of this app pool is unavailable, please check manually!"
                                                                }
                                                                else {
                                                                    Write-Output "[MSG] : Unable to load site of this app pool[Status Code = $HTTP_Status], please check manually!"
                                                                }
                                                                $HTTP_Response.Close() 
                                                            }
                                                            else {
                                                                Write-Output "[MSG] : Didn't get response from '$WebUrl'. Check site manually"
                                                            }
                                                        }
                                                        catch {
                                                            Write-Output "[ERROR] : $($_.Exception.Message). Please check response code." 
                                                        }
                                                    }
                                                    else {
                                                        Write-Output "[MSG] : Could not bypass cettificate error. Please login and try manually" 
                                                    }

                                                }
                                                else {
                                                    Write-Output "[MSG] : Unable to get web url for '$site'"
                                                }
                                            }
                                            else {
                                                Write-Output "[MSG] : Unable to get response url, please check manually!"
                                            }
                                        }
                                        else {
                                            Write-Output "[MSG] : No site found for application pool '$($AppPool.name)'"
                                        }
                                    }
                                    catch {
                                        Write-Output "[ERROR] : $($_.Exception.Message)"
                                    }

                                }
                                else {
                                    Write-Output " AppPool '$($AppPool.Name)' not started. Kindly check the issue manually."
                                }
                               
                            }
                            catch {
                                #Write-Output "Unable to Start Web App Pool $($AppPool.Name)"
                                Write-Output "Exception: $($_.Exception.Message)."
                            }
                        }

                    }
                    else {
                        Write-Output "`n`n[MSG] : User didn't choose to do troubleshooting"
                    }

                }
                catch {
                    Write-Output "Exception: $($_.Exception.Message)"
                }

            }
           
            else {
                Write-Output "Unable to resolve AppPool '$($AppPool.Name)' Status --> '$($AppPool.State)'"
            }

        } #If AppPool Exists
        else {
            Write-Output "`nUnable to get the details of $($Name) AppPool ($errormsg)"
        }
    } #Function End
    
    if ([String]::IsNullOrWhiteSpace($poolname)) {
        if([string]::IsNullOrEmpty($ApplicationPoolName)){
            Write-Output "`n[MSG] : No application pool found either from event or from user. Hence will not do any troubleshooting"
        }
        else {
            try {
                Troubleshoot -Name $ApplicationPoolName    
            }
            catch {
                Write-Output "`n[ERROR] : $($_.Exception.Message)"    
            }
        }
        
    } #end if block for empty value of user input
    else {
        if([string]::IsNullOrEmpty($ApplicationPoolName)){
            try {
                
                Troubleshoot -Name $poolname    
            }
            catch {
                Write-Output "`n[ERROR] : $($_.Exception.Message)"    
            }
        }   
        else {
            $values = $poolname, $ApplicationPoolName
            foreach ($value in $values) {
                try {
                    Troubleshoot -Name $value    
                }
                catch {
                    Write-Output "`n[ERROR] : $($_.Exception.Message)"    
                }
            }    
        } 
    } #end else block for user input value

   
}# end if block of Import Web Administration Module
else {
    Write-Output "`n[MSG] : Unable to execute script because 'WebAdministration' module is not loaded "
}