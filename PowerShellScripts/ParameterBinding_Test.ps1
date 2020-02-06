#Parameter binding ByValue only
Function Get-Multiplication
{
     [CmdletBinding()]
      Param(      
            [Parameter(Mandatory=$true,
            ValueFromPipeline)]
            [int[]]$Number
            )
    Begin
    {
        Write-Verbose -Message "Multiplying numbers ..." -Verbose
        [int]$result=1
    }
    Process
    {
        $result = $_*$result
        #$result

    }
    End
    {
        Write-Verbose -Message "Multiplication output = $result" -Verbose
    }

}

#Parameter binding ByValue and ByPropertyName
Function Get-ServiceDetails
{
     [CmdletBinding()]
      Param(      
            [Parameter(Mandatory=$true,
            ValueFromPipeline,
            ParameterSetName="Set1")]
            [System.ServiceProcess.ServiceController[]]
            $input_object,
            

          
            [Parameter(Mandatory=$true,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Set2")]
            [String[]]$names
            )

    Begin
    {
        Write-Verbose -Message "Getting details of services ...`n" -Verbose
        $count = 0
    }
    
    Process
    {
        try
        {
            if($input_object)
            {
                Write-Output "$($_.Name) - $($_.Status)" -ErrorAction Stop -ErrorVariable err
            }
            else
            {
                $data=Get-Service -Name $_ -ErrorAction Stop -ErrorVariable +err
                Write-Output "$($data.Name) - $($data.Status)"
                #$names.Name
            }
            $count++
        }
        catch
        {
            
        }

    }
    
    End
    {
        if($err)
        {
            Write-Output "`n*********Errors occurred during script execution**********`n"
            $err
        }
        Write-Verbose -Message "Execution completed successfully for $($count) services" -Verbose
    }

}
