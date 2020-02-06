<#
.SYNOPSIS
    Automation Task to check  NTFRS - Journal Wrap Errors detected on Domain Controller.

.DESCRIPTION
    This Automation Task checks whether  NTFRS - Journal Wrap Errors detected on Domain Controller or not

.NOTES    
 Name: NOCAT-AD-NTFRS Journal Wrap Error On DC
 Category : Setup
 Author: Imran Khan  
 Version: 1.0 
 DateCreated: 2019-03-29 
 DateModified: 2019-June-04
 Logical Testing Performed by Sarang
.PARAMETER 
    $AuthoritativeRestore = Perform Authoritative restore in Single DC Environment.
    $AuthMultidc = Perform Authoritative Restore in Multiple DC scenario 
    $nonauth = Perform Non-Authoritative Restore in Multi DC scenario
    $isRestartReq=$true if true means enable and restart service if needed . 
.EXAMPLE
 .\GRT_3995_NTFRS_Journal_Wrap_Error_On_DC.ps1 
#>
$nonauth = $False 
$AuthoritativeRestore =$True
$AuthMultidc = $false

<# Architecture check started and PS changed to the OS compatible #>
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64")
{
if ($myInvocation.Line) 
{
  &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
}else{
    &"$env:systemroot\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
  }
exit $lastexitcode
}
<#Architecture check completed #>

<# Compatibility check if found incompatible will exit #>
try
{
  [double]$OSVersion = [Environment]::OSVersion.Version.ToString(2)
  $PSVersion = (Get-Host).Version
  if(($OSVersion -lt 6.1) -or ($PSVersion.Major -lt 2))
  {
    Write-Output "[MSG: System is not compatible with the requirement. Either machine is below Windows 7 / Windows 2008R2 or Powershell version is lower than 2.0]"
    Exit
  }
}catch { Write-Output "[MSG: ERROR : $($_.Exception.message)]"}
<# Compatibility Check Code Ends #>

############################################################################
# Function to execute non powershell commands
############################################################################
Function ExecuteCMDCommands($Command) {
    try {
        if ($Command) {
            $finalCmd = "cmd /c " + $Command + " '2>&1'"
            $msg = (Invoke-Expression -Command $finalCmd -ErrorAction Stop)
            Write-Output $msg     
        }
        else { Write-Output "Command can not be null" }
    }
    catch
    { Write-Output "Error:" $msg }
}#End function ExecuteCMDCommands

#Function to run dcdiag
Function get-dcdiag {
$RequiredInfomultiDC = @()
$RequiredInfomultiDC += "Output of dcdiag /q command"
$dcdiagmultidc =  ExecuteCMDCommands -Command 'dcdiag /q'
if($dcdiagmultidc) {
$RequiredInfomultiDC += $dcdiagmultidc
} 
else 
{
  $RequiredInfomultiDC += "No errors found in dcdiag /q"
}
Write-Output $RequiredInfomultiDC
}
#End of Function DCDIAG

#Start of Non-authoritative Restore function
function Perform-nonauthrestore {

  Write-Output "$("="*40)`nYou have selected for Non-Authoritative Restore of Sysvol this will be executed only if there are multiple DC's"
  try
  {
    if ((Get-ChildItem $Policypath).count -eq $GPMCcount){
      #Perform non-authoritative Restore of Sysvol
      $RegistryPath="HKLM:\SYSTEM\CurrentControlSet\Services\NtFrs\Parameters\Backup\Restore\Process at Startup"
      if(!(Test-Path $RegistryPath))
      {
        #Creating new entry for $RegistryPath
        New-Item -Path $RegistryPath -ErrorAction Stop|Out-Null
      }
      #Setting the value for $RegistryPath
      Set-ItemProperty -Path $RegistryPath -Type DWORD -Force -name 'BurFlags' -value 210 -ErrorAction Stop
      if(Get-Service |Where-Object{$_.Name -eq "ntfrs"})
      {
        try
        {
          $StartTime= Get-Date
          $ServiceStatus=Try {Restart-service ntfrs  -Force -ErrorAction Stop -WarningAction SilentlyContinue  -PassThru} catch {$_.exception.message}
          #wait for service to be in running state till 30 seconds
          $ServiceStatus.WaitForStatus("Running","00:00:30") 
          $flag=$false
          $count=0
          while($count -lt 20)
          {
            #search for Event id 13516 after restart of service
            $arg = @{
              "StartTime" = $StartTime
              "EndTime" = $(get-date)
              "LogName" = "File Replication Service"
              "ID" = "13516"
            }
            $event=Get-WinEvent -FilterHashtable $arg -MaxEvents 1 -ErrorAction SilentlyContinue
            if($event)
            {
              $flag=$true
              break;
            }
            else
            {
              $count++
            }
          }#While Close
          if($flag -eq $true)
          {
            Write-Output "$("="*40)`nEvent id 13516 is generated after performing Non-Authoritative restore followed by FRS service restart and the time of 13516 event is $($event.TimeCreated)"
          }
          else
          {
            Write-Output "$("="*40)`nEvent id 13516 is not generated after service restart, hence issue is not resloved backup of Sysvol has been kept on %systemvolume%\sysvolbackupnoc"
            get-dcdiag
            EXIT
          }
          # Check folder count in sysvol path
          $FolderCountAfter=(Get-Childitem -Recurse -Force -path $sysvolpath.SysVol).count
          if($FolderCount -eq $FolderCountAfter)
          {
           Write-Output "$("="*40)`nIssue is Resolved.`n Backup of Sysvol was taken on %systemvolume%\sysvolbackupnoc before performing Non-authoritative restore"
           
          }
          else
          {
            Write-Output "$("="*40)`nFile/Folder count mismatch after performing the Non-Authoritative Restore for SYSVOL folder, please login and verify.Backup of Sysvol has been stored on %systemvolume%\sysvolbackupnoc"
          }
        }
        catch
        {
          Write-Output $_.Exception.Message
          get-dcdiag
          EXIT
        }
      }
      else
      {
        Write-Output "$("="*40)`nService 'NTFRS' is not present on the server"
        get-dcdiag
        EXIT
      }
    }
    else {
      Write-Output "$("="*40)`nCount of GUID folders under $Policypath does not match the count of GPO's present in AD Database, please login and verify the same `n Non-Authoritative Restore has not been performed.  "
    }
  } #end try block
  catch
  {
      Write-Output $_.Exception.Message
  }
  }
 #End of Function Non-authoritative Restore 
 
 #Start of authoritative Restore function 
  function Perform-authrestore {
  
    Write-Output "$("="*40)`nYou have selected for Authoritative Restore of Sysvol"
    try
    {
      if ((Get-ChildItem $Policypath).count -eq $GPMCcount){
      #Perform authoritative Restore of Sysvol
      $RegistryPath="HKLM:\SYSTEM\CurrentControlSet\Services\NtFrs\Parameters\Backup\Restore\Process at Startup"
      if(!(Test-Path $RegistryPath))
      {
        #Creating new entry for $RegistryPath
        New-Item -Path $RegistryPath -ErrorAction Stop|Out-Null
      }
      #Setting the value for $RegistryPath
      Set-ItemProperty -Path $RegistryPath -Type DWORD -Force -name 'BurFlags' -value 212 -ErrorAction Stop
      if(Get-Service |Where-Object{$_.Name -eq "ntfrs" })
      {
        try
        {
          $StartTime= Get-Date
          $ServiceStatus=Try {Restart-service ntfrs  -Force -ErrorAction Stop -WarningAction SilentlyContinue -PassThru} catch {$_.exception.message}
          #wait for service to be in running state till 30 seconds
          $ServiceStatus.WaitForStatus("Running","00:00:30") 
          $flag1=$false
          $count=0
          while($count -lt 10)
          {
            #search for Event id 13516 after restart of service
            $arg = @{
              "StartTime" = $StartTime
              "EndTime" = $(get-date)
              "LogName" = "File Replication Service"
              "ID" = "13516"
            }
            $event=Get-WinEvent -FilterHashtable $arg -MaxEvents 1 -ErrorAction SilentlyContinue
            if($event)
            {
              $flag1=$true
              break;
            }
            else
            {
              $count++
            }
          }#While Close
          if($flag1 -eq $true)
          {
            Write-Output "$("="*40)`nEvent id 13516 is generated after performing Authoritative restore followed by FRS service restart and the time of 13516 event is $($event.TimeCreated)"
          }
          else
          {
            Write-Output "$("="*40)`nEvent id 13516 is not generated after service restart, hence issue is not resloved backup of Sysvol has been kept on %systemvolume%\sysvolbackupnoc"
            EXIT
          }
          # Check folder count in sysvol path
          $FolderCountAfter=(Get-Childitem -Recurse -Force -path $sysvolpath.SysVol).count
          if($FolderCount -eq $FolderCountAfter)
          {
           Write-Output "$("="*40)`nIssue is Resolved.`n Backup of Sysvol was taken on %systemvolume%\sysvolbackupnoc before performing authoritative restore"
          }
          else
          {
            Write-Output "$("="*40)`nFile/Folder count mismatch after performing the Authoritative Restore for SYSVOL folder, please login and verify.Backup of Sysvol has been stored on %systemvolume%\sysvolbackupnoc"
          }
        }
        catch
        {
          Write-Output $_.Exception.Message
          get-dcdiag
          EXIT
        }
      }
      else
      {
        Write-Output "$("="*40)`nService 'NTFRS' is not present on the server"
        get-dcdiag
        EXIT
      }
      }
      else {
        Write-Output "$("="*40)`nCount of GUID folders under $Policypath does not match the count of GPO's present in AD Database, please login and verify the same `nAuthoritative Restore has not been performed.  "
      }
  } #End try block
  catch
  {
      Write-Output $_.Exception.Message
  }
}
#End of Function authoritative Restore 

try
{
  #Check the system’s Windows NT kernel version:
  $kernelVersion=(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion
  #If the kernel version is less than 6.1, exit with error: Legacy OS found.
  if($kernelVersion -lt 6.1)
  {
    Write-Output "$("="*40)`nLegacy OS found Please login to the server and proceed further"
    EXIT
  }
  #Check PS Version, required 2.0
  if($PSVersionTable.PSVersion.Major -lt 2)
  {
    Write-Output "Powershell version is not compatible on this server, please login to the server and proceed further"
    EXIT
  }
  $OSInfo=Get-WmiObject -Class Win32_OperatingSystem -Property * -ErrorAction Stop
  #Check whether current machine is a domain controller
  if($OSInfo.ProductType -ne 2)
  {
   Write-Output "Current machine is not a domain controller"
   EXIT
  }
  #Check AD module is installed or not
  if (!(Get-Module -ListAvailable -Name ActiveDirectory))
  {
    Write-Output "Active Directory module is not installed"
    EXIT
  }      
  #Import AD module
  Import-Module ActiveDirectory -ErrorAction Stop
  #Check the Content of Sysvol Folders
  $sysvolpath=(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\" -ErrorAction SilentlyContinue| Select-Object 'Sysvol').sysvol
  $Policypath=$Sysvolpath+"\"+$env:USERDNSDOMAIN+"\policies"
  $scriptpath=$Sysvolpath+"\"+$env:USERDNSDOMAIN+"\scripts"
  if(Test-path $Policypath) 
  {
    Write-Output "$("="*40)`n$((Get-ChildItem $Policypath).count) GUID Folders present under the Policies folder in SYSVOL"
  }
  else 
  {
    Write-Output "$("="*40)`nCould not find the SYSVOL path for this server."
    Write-Output "There is no 'Policies' folder under Sysvol directory hence please get the backup from MSP"
    get-dcdiag
    Exit
  }
  if(test-path $scriptpath) 
  {
    Write-Output "$("="*40)`n$((Get-ChildItem $scriptpath).count) files/Folders present under the Scripts folder in SYSVOL"
  }
  else 
  {
    Write-Output "$("="*40)`nCould not find the path for Scripts folder under sysvol on this server."
  }

  ############# Check the number of GPO present in AD ###############
  $DNName=(Get-ADDomain -ErrorAction Stop | Select-Object DistinguishedName).DistinguishedName
  $GPMCcount=(Get-ChildItem -Path "AD:\CN=Policies,CN=System,$DNName" |Measure-Object).count
  Write-output "$("="*40)`nThere are $($GPMCcount) Group Policy Objects present under Active Directory Database"
  if($GPMCcount -eq (Get-ChildItem $Policypath).count) 
  {
    Write-Output "$("="*40)`nNumber of GUID Folders under sysvol are same as number of Group Policy Objects present under Active Directory Database"
  }

  else 
  {
    Write-Output "$("="*40)`nThere is mismatch in the number of GUID Folders under sysvol and Group Policy Objects present under Active Directory Database, please verify the same"
  }
#------------------
  #Check the number of DC’s in domain 
  $dcarryLF=New-Object System.Collections.ArrayList
  $dcl=Try{Get-ADDomainController -Filter * -erroraction Stop | Select-Object -ExpandProperty name} catch {$_.Exception.Message}
  $dccount=$dcl.count
  $i=0
  $dcl_contest=While ($i -lt $dccount)
  {
    $a="" 
    $a=Test-Connection $dcl[$i] -ErrorAction SilentlyContinue #is not supported to powershell 2.0
    if(-not $a) 
    {
      $dcarryLF.Add($dcl[$i])
    }
    $i++
  }
  if($dccount -ge 2)
  {
      Write-Output "$("="*40)`nThere are $($dccount) domain controllers in the environment, please login and troubleshoot"
      if($dcarryLF.count -ge 1)
      {
        Write-output "$("="*40)`nBelow are the DC List for which Test Connection failed"
        $dcarryLF
      }
  }

    #Check NTFRS service status
    $Service = Get-WmiObject -Class Win32_Service -Property StartMode,State -Filter "Name='NTFRS'"
    if($Service)
    {
        $StartType=$null
        $startType=$Service.StartMode
        Write-Output "$("="*40)`n'NTFRS' Service is $($startType) and $($Service.state)"
        if(($startType -eq "Auto" -or $startType -eq "Manual") -and $Service.State -eq "Stopped" )
        {
            try
            {
                 if($startType -eq "Manual")
                 {
                    Set-Service -Name "NTFRS" -StartupType Automatic -ErrorAction Stop
                    Write-Output "$("="*40)`nStartup Type has been set to 'Automatic' mode"
                 }
                 Start-Service "NTFRS" -ErrorAction Stop -WarningAction SilentlyContinue
                 Write-Output "'NTFRS' Service has been started"
            }
            catch
            {
                Write-Output $_.Exception.Message
                EXIT
            }
         }
         elseif(($isRestartReq -eq $true) -and $startType -eq "Disabled")
         {
             try
             {
                Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
                Write-Output "$("="*40)`nStartup Type has been set to Automatic"
                $serviceState=Start-Service $ServiceName -ErrorAction Stop -WarningAction SilentlyContinue
                Write-Output "'NTFRS' Service has been started"
             }
             catch
             { Write-Output "Unable to change startup type of service from disable to enable"}
         } 
         else
         {
           Write-Output "$("="*40)`nNo action performed on the 'NTFRS' service"
         }
    }
    else
    {
        Write-Output "$("="*40)`n'NTFRS' Service not found on this machine"
    }
    #Check whether Event log is present or not
    $logExist=Get-WinEvent -ListLog * -ErrorAction SilentlyContinue |Where-Object{$_.LogName -eq "File Replication Service"}
    if(!$logExist)
    {
      Write-Output "$("="*40)`n'File Replication Service' event log is not present on the server, could not perform further operations"
      get-dcdiag
      EXIT
    }
    else
    {
        #Steps for Single & Multiple DC Scenario
        try
        {
            $event13516=(get-winevent -FilterHashtable @{Logname='File Replication Service';ID=13516}  -MaxEvents 1 -ErrorAction Stop ).TimeCreated
        }
        catch
        {
            if ($_.Exception -match "No events were found that match the specified selection criteria") {
                Write-Output "No event id 13516 found in File Replication Service";
                $event13516 = 0
            }
            else
            {
                Write-Output $_.Exception.message
            }
        }
        try
        {
            $event13568=(get-winevent -FilterHashtable @{Logname='File Replication Service';ID=13568}  -MaxEvents 1 -ErrorAction Stop ).TimeCreated
        }
        catch
        {
            if ($_.Exception -match "No events were found that match the specified selection criteria") {
                Write-Output "No event id 13568 found in File Replication Service";
                $event13568 = 0
            }
            else
            {
                Write-Output $_.Exception.message
            }
        }
    
        if(($event13516 -ne 0) -and ($event13568 -ne 0 ))
        {
            Write-Output "$("="*40)`nLast Event ID 13516 occurred at $($event13516)"
            Write-Output "Last Event ID 13568 occurred at $($event13568)"
            if($event13516 -gt $event13568)
            {
                $netShareOutput=Invoke-Expression "net share" -ErrorAction Stop
                Write-Output "$("="*40)`nEvent ID 13516 has been generated after 13568 hence issue is considered as resolved"
                Write-Output "`NET SHARE OUTPUT`n"
                Write-Output $netShareOutput
                Write-Output $("-"*20)$("-"*20)
                get-dcdiag
                EXIT
            }
            else
            {
                Write-Output "$("="*40)`nEvent ID 13516 has been generated before 13568 hence there is an issue"
            }
        }
        else
        {
            if(($event13516 -eq 0) -and ($event13568 -eq 0 ))
            {
                write-output "$("="*40)`nEvent id 13516 and 15568 have not occurred"
            }
            elseif(($event13516 -eq 0) -and ($event13568 -ne 0 ))
            {
                write-output "$("="*40)`nEvent id 13516 does not occurred but Event id 13568 has occurred at $($event13568)"
            }
            else
            {
                write-output "$("="*40)`nEvent id 13516 has occurred at $($event13516) but Event id 13568 does not occurred"
            }

        }

    } #end else block

    $DNName=(Get-ADDomain -ErrorAction Stop | Select-Object DistinguishedName).DistinguishedName
    #check whether Multiple replication groups are present or not
    $ItemList=Get-ChildItem -Path "AD:\CN=File Replication Service,CN=System,$DNName" -ErrorAction Stop
    if($ItemList.count -gt 1)
    {
      Write-Output "$("="*40)`nMultiple replication group found please review replication groups other than `“Domain System Volume`”."
      Write-Output $ItemList
      get-dcdiag
      EXIT
    }

    #---------------
    #Gather SYSVOL information as there is single replication group present
    $sysvolpath=(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\" -ErrorAction SilentlyContinue| Select-Object 'Sysvol')
    $sysvoldrive=(Get-Item ($sysvolpath.'SysVol')).PSDrive.Name
    $sysvolInfo=Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq ($sysvoldrive + ":") }| Select-Object DeviceID, FileSystem, @{L="PercentFree";E={"{0:N2}" -f (($_.freespace/$_.size)*100)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}},@{L="Dirty_Status";E={fsutil dirty query $_.DeviceID}}
    #Check if sysvol drive space is less then 1 GB
    if($sysvolInfo.FreeSpace -lt 1)
    {
      Write-Output "$("="*40)`nDrive holding sysvol is full, please free some drive space"
      get-dcdiag
      EXIT
    }
    #Check Drive Dirty Status
    if($sysvolInfo.Dirty_Status -match "is Dirty")
    {
      Write-Output "$("="*40)`nDrive Containing Sysvol folder is not consistent, please fix the disk issues"
      get-dcdiag
      EXIT
    }
    
    ####### Count the number of folders under $sysvolpath ########
    $FolderCount=(Get-Childitem -Recurse -Force -path $sysvolpath.SysVol).count
    $SourcePath=($sysvolpath).sysvol+"`\*"
    $DateTime=Get-date -Format "yyyyMMddHHmmss"
    $destinationDirectory=$env:SystemDrive+"\SysVolBackupNoc"+"\Sysvolbackup"+$DateTime
    try
    {
        New-Item -Path $destinationDirectory -ItemType Directory -ErrorAction Stop |Out-Null
        #Copy the folder and its contents from $sysvolpath to sysvolbackup folder under %systemDrive%\SysvolbackupDateTime
        Copy-Item -Path $SourcePath -Destination $destinationDirectory -Force -Recurse -ErrorAction Stop
    }
    catch
    {
        Write-Output $_.Exception.Message
        EXIT
    }
  
    ####### For Multiple DC scenario, print repadmin command output and exit ########
    if($dccount -gt 1 -and $nonauth -eq $true) 
    {
        Write-Output "$("="*40)`nRecursive Files and Folders count under sysvol path: $($FolderCount)"
        Perform-nonauthrestore  #Calling nonauthrestore function
    }
    elseif (($dccount -eq 1 -and $AuthoritativeRestore -eq $true) -or ($dccount -gt 1 -and $AuthMultidc -eq $true))
    {
        Perform-authrestore  #calling authrestore fucntion
    }
    else
    {	
        Write-Output "$("="*40)`nSince you have not selected to perform authoritative or non-authoritative restore, same has not not been performed"
    }
    Write-Output "$("="*40)`n`DC DIAG OUTPUT`n"
    get-dcdiag
    if ($dccount -gt 1 )
    {
        $repadminOutput=Invoke-Expression "repadmin /showreps" -ErrorAction Stop
        Write-Output $repadminOutput
    }
    EXIT  	
} #try close
catch
{
  Write-Output $_.Exception.Message  
}