<#
.SYNOPSIS
 Automation task to check whether a user account has UPN value or not 

.DESCRIPTION
 This automation task checks for UPN value of user and print the list of users without UPN under Suspecious User List.

.NOTES    
 Name: GRT_4129_Security_Notification_Ticket_Check.ps1
 Author: Imran Khan  
 Version: 1.3 
 DateCreated: 26-04-2019
 UpdatedOn : 15-05-2019
.PARAMETER 
    None 
#>
<# Architecture check started and PS changed to the OS compatible #>
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if ($myInvocation.Line) {
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
  exit $lastexitcode
  }
  <#Architecture check completed #>
  <# Compatibility check if found incompatible will exit #>
  try{
    [double]$OSVersion = [Environment]::OSVersion.Version.ToString(2)
    $PSVersion = (Get-Host).Version
    if(($OSVersion -lt 6.1) -or ($PSVersion.Major -lt 2))
    {
        Write-Output "[MSG: System is not compatible with the requirement. Either machine is below Windows 7 / Windows 2008R2 or Powershell version is lower than 2.0"
        Exit
    }
  }catch { Write-Output "[MSG: ERROR : $_.Exception.message]"}
  <# Compatibility Check Code Ends #>
   ############################################################################
    # Function to List Domain Controller in the domain environment
    ############################################################################ 
  Function DCListInfo() 
   {
    try{    
        $sysinfo = Get-WmiObject -Class Win32_ComputerSystem
        $Command = "nltest /dclist:"+$sysinfo.domain
        $DCList = Invoke-expression $Command
        Write-Output $DCList
    }catch{
        Write-Output "Unable to provide Domain Controller List"
    }
   }
  
    ############################################################################
    # Function to check suspicious AD Users Details
    ############################################################################
    Function GetSuspiciousUsersInfo()
    {
      try{
            #Check AD module is installed or not
            if (!(Get-Module -Name ActiveDirectory)) {
            try{
                  #Importing AD module to use AD related commands
                    Import-Module ActiveDirectory -ErrorAction Stop
                }catch{
                    Write-Output "The specified module ActiveDirectory was not loaded because no valid module file was found in any module directory."
                    EXIT
                }
            }
           
            #Get Users Details
            try{
            $SuspiciousUsers = Get-ADUser -Filter * | Where-Object { [string]::IsNullOrEmpty($_.UserPrincipalName) -and ("Guest","Administrator","krbtgt","DefaultAccount" -notcontains $_.SamAccountName) } | Select-Object -ExpandProperty Name
            }catch{ 
                if ($_.Exception -match "Unable to find a default server with Active Directory Web Services running")
                {
                    Write-Output " Active Directory Web Services is not running. Please start and try again";
                    Exit
                }
                else
                {
                  Write-Host $_.Exception.message
                  Exit
                }
            }
            
            if(($SuspiciousUsers|Measure-Object).count -eq 0)
            {
                Write-Output "No suspicious user found"
                EXIT
            }
            else
            {
                Write-Output "List of suspicious users found with no UserPrincipalName:"
                $SuspiciousUsers
            }
        }catch{
                Write-Error $_.Exception.Message
        }
    }#Function Close

try{
    $DomainRole= (Get-WmiObject -Class win32_ComputerSystem).DomainRole
    if(($DomainRole -eq 4) -or ($DomainRole -eq 5))
    { 
        #Calling Function GetUsersInfo
        GetSuspiciousUsersInfo
    }
    elseif(($DomainRole -eq 3) -or ($DomainRole -eq 1))
    {
        Write-Output "This is not a PDC/ADC/RODC. Please run this script on a DC."
        DCListInfo    
        EXIT
    }
    else
    {
        Write-Output "Machine is not in Domain Environment. Try automation task on Domain Controller"
    }   
}catch{
    Write-Error $_.Exception.Message
    EXIT
}


