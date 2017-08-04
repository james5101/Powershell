
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([Hashtable])]
	param
	()
	
	
	begin
	{
		try
		{
			$Service = Get-Service -Name MSMQ -ErrorAction Stop
			
			if ($Service.Status -ne 'Running')
			{
				throw 'Please ensure MSMQ service is running'
			}
		}
		catch
		{
			throw $_.Exception.Message
		}
	}
	
	process
	{
		$MsmqQueueManager = Get-MsmqQueueManager -ErrorAction SilentlyContinue
		
		if ($MsmqQueueManager)
		{
			Write-Verbose -Message  'Found QueueManager'
		}
		
		else
		{
			Write-Verbose -Message 'QueueManager not found, please check MSMQ'
		}
		
		$ReturnValue = @{
			QueueQuota = $MsmqQueueManager.TotalMessageStoreInKilobytes
		}
		
		return $ReturnValue
		
	}
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([Boolean])]
	param
	(
		[Parameter(Mandatory = $true)]
		[UInt32]$QueueQuota
	)
	
	$TargetResource = Get-TargetResource -Verbose
	
	$PSBoundParameters.GetEnumerator() |
            Where-Object {$_.Key -in @('QueueQuota')} |
            ForEach-Object {

                $PropertyName = $_.Key

                if ($TargetResource."$PropertyName" -cne $_.Value)
                {
                    $InDesiredState = $false

                    "Property '{0}': Current value '{1}'; Desired value: '{2}'." -f $PropertyName, $TargetResource."$PropertyName", $_.Value |
                    Write-Verbose
		}
		else
		{
			$InDesiredState = $true
		}
	}
	
	if ($InDesiredState -eq $True)
	{
		Write-Verbose -Message "The target resource is already in the desired state. No action is required."
	}
	else
	{
		Write-Verbose -Message "The target resource is not in the desired state."
	}
	return $InDesiredState
}

function Set-TargetResource
{
	[CmdletBinding()]
	
	param
	(
		[Parameter(Mandatory = $true)]
		[UInt32]$QueueQuota
	)
	
	$GetValue = Get-TargetResource
	$TargetResource = Test-TargetResource -QueueQuota $QueueQuota -Verbose
	
	if ($TargetResource -eq $false)
	{
		Set-MsmqQueueManager -MessageQuota $QueueQuota  -Confirm:$false
		
		"Current value '{0}'; Setting value to: '{1}'." -f $GetValue.QueueQuota, $QueueQuota |
		Write-Verbose
	}
	else
	{
		return 	
	}
}
