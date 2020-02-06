<#
.SYNOPSIS
 Automation task to check whether a user account has UPN value or not 

.DESCRIPTION
 This automation task checks for UPN value of user and print the list of users without UPN under Suspecious User List.

.NOTES    
 Name: GRT_4129_Security_Notification_Ticket_Check.ps1
 Author: Imran Khan & Akshi Srivastava
 Version: 1.5
 DateCreated: 26-04-2019
 UpdatedOn : 19-06-2019

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
        $sysinfo = Get-WmiObject -Class Win32_ComputerSystem -ErrorActon Stop
        $Command = "nltest /dclist:"+$sysinfo.domain
        $DCList = Invoke-expression $Command
        Write-Output $DCList
    }catch{
        Write-Output "Unable to provide Domain Controller List"
    }
   }
  

    ############################################################################
    # Function to display current audit policy settings
    ############################################################################
    Function DisplayAuditPolicy
    {
        try
        {
            write-output "`nFetching Audit policy settings for subcategory - 'Security Group Management' & 'User Account Management' under category - 'Account Management'...."
            $output=auditpol /get /category:"Account Management"|select-string -SimpleMatch -Pattern "Security Group Management","User Account Management" -ErrorAction Stop| ForEach-Object { ($_.Line.Trim())}
            if($null -ne $output)
            {
                write-output "`n===========================================================`nThe current audit policy settings are:"
                $output
                write-output "==========================================================="
            }
            else
            {
                write-output "`nNo audit policy settings found for those subcategories under ‘Account Management’ category"
            }

        }
        catch
        {
            Write-Output "`nUnable to fetch audit policy settings!"
            Write-Error $_.Exception.Message
            
        }
    
    }#Function end for audit policy setting status

    ############################################################################
    # Function to display security event logs for event id 4720,4722,4725,4728 and 4732
    ############################################################################
    Function GetEventLogs
    {
        try
        {
            #Gathering all available occurrences of security event log for event id - 4720,4722,4725,4728,4732
            $Duration = Get-EventLog -LogName 'Security' -ErrorAction stop |Select-object -property TimeGenerated
            if($Null -ne $Duration)
            {
                $Last = ($Duration|select-object -Last 1).TimeGenerated
                $Start = ($Duration|select-object -First 1).TimeGenerated
                $Days = (New-TimeSpan -Start $Last -End $Start -ErrorAction Stop).Days

                Write-Output "`nDuration of Security Events Logs Available on the System:"
                Write-Output "$Last - $Start = $Days Days"
                if($Days -gt 30)
                {
                    #$Events = Get-EventLog -LogName 'Security' -ErrorAction stop | Where-Object { $_.EventID -eq 4720 -or $_.EventID -eq 4722 -or $_.EventID -eq 4725 -or $_.EventID -eq 4728 -or $_.EventID -eq 4732}|Select-Object @{ e={"Security"}; l='LogName' }, @{ e={$_.EventID}; l='EventID' },Message,@{ e={$_.TimeGenerated}; l='Created' } 
                    $Events1 = Get-EventLog -LogName 'Security' -Before (Get-Date) -After ((Get-Date).AddDays(-31)) -ErrorAction stop | Where-Object { $_.EventID -eq 4720 -or $_.EventID -eq 4722 -or $_.EventID -eq 4725 -or $_.EventID -eq 4728 -or $_.EventID -eq 4732}|Select-Object @{ e={"Security"}; l='LogName' }, @{ e={$_.EventID}; l='EventID' },Message,@{ e={$_.TimeGenerated}; l='Created' } 
                    #Check for available event occurrences
                    if($Null -ne $Events1)
                    {
                        Write-Output "`nAll occurrences of Event ID 4720,4722, 4725, 4732 and 4728 in the Windows Security Event Log in last 30 days : "
                        Write-Output "==========================================================="
                        $Events1
                        Write-Output "==========================================================="
                    }
                    else
                    {
                        Write-Output "`nNo events are found in security event log for Event ID - 4720,4722,4725,4728 and 4732 in last 30 days"
                    }
                }
                else
                {
                    $Events2 = Get-EventLog -LogName 'Security' -ErrorAction stop | Where-Object { $_.EventID -eq 4720 -or $_.EventID -eq 4722 -or $_.EventID -eq 4725 -or $_.EventID -eq 4728 -or $_.EventID -eq 4732}|Select-Object @{ e={"Security"}; l='LogName' }, @{ e={$_.EventID}; l='EventID' },Message,@{ e={$_.TimeGenerated}; l='Created' } 
                    if($Null -ne $Events2)
                    {
                        Write-Output "`nAll occurrences of Event ID 4720,4722, 4725, 4732 and 4728 in the Windows Security Event Log in last $Days days : "
                        Write-Output "==========================================================="
                        $Events2
                        Write-Output "==========================================================="
                    }
                    else
                    {
                        Write-Output "`nNo events are found in security event log for Event ID - 4720,4722,4725,4728 and 4732 in last $Days days"
                    }
                }
            }
            else
            {
                Write-Output "`nThere are no events available in security log to display. Please check security event log for corruption."    
            
            }
        } #End try block
        Catch
        {
            Write-Output "`nError occured gathering events in security event log"
            Write-Error $_.Exception.Message
        }        
    } # Function end for checking occurrences of log events



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
                    Write-Output "`nThe specified module ActiveDirectory was not loaded because no valid module file was found in any module directory."
                    EXIT
                }
            }
           
            #Get Users Details
            try{
            $SuspiciousUsers = Get-ADUser -Filter * | Where-Object { [string]::IsNullOrEmpty($_.UserPrincipalName) -and ("Guest","Administrator","krbtgt","DefaultAccount" -notcontains $_.SamAccountName) } | Select-Object -ExpandProperty Name
            }catch{ 
                if ($_.Exception -match "`nUnable to find a default server with Active Directory Web Services running")
                {
                    Write-Output "`nActive Directory Web Services is not running. Please start and try again";
                    Exit
                }
                else
                {
                  Write-Output $_.Exception.message
                  Exit
                }
            }
            
            if(($SuspiciousUsers|Measure-Object).count -eq 0)
            {
                Write-Output "`nNo suspicious user found"
                EXIT
            }
            else
            {
                write-output "`n==========================================================="
                Write-Output "List of suspicious users found with no UserPrincipalName:"
                $SuspiciousUsers
                write-output "==========================================================="
                GetEventLogs

            }
        }catch{
                Write-Error $_.Exception.Message
        }
    }#Function Close

        
try{
    $DomainRole= (Get-WmiObject -Class win32_ComputerSystem).DomainRole
    if(($DomainRole -eq 4) -or ($DomainRole -eq 5))
    { 
        #Calling Functions
        DisplayAuditPolicy
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


