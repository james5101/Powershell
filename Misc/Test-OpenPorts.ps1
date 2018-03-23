function Test-OpenPorts
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
	(
		[Parameter(Mandatory = $true,
				  ValueFromPipeline = $true,
				  ValueFromPipelineByPropertyName = $true
		)]
		[ValidateNotNullOrEmpty()]
		[Alias('CN', 'Name')]
		[String]$ComputerName,

    
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true
		)]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(0,65535)]
		[int]$PortNumber = 80
	
	)
   
    
    Process
    {
        try
        {
            
            $tcptest = Test-NetConnection -ComputerName $ComputerName  -Port $PortNumber  -ErrorAction Stop
        }
        catch
        {
            "There was an error" | Write-Verbose
             
        }
        if ($tcptest.TcpTestSucceeded -eq $true)
        {
            "Port {0} on {1} is open and responding" -f $PortNumber, $ComputerName | Write-Verbose
            $returnObj = [PScustomObject]@{Computer = $ComputerName; Port = $PortNumber; IsOpen = $true}
        }
        if ($tcptest.TcpTestSucceeded -eq $false)
        {
            "Port {0} on {1} is not open and not responding" -f $PortNumber, $ComputerName | Write-Verbose -WarningAction Continue
            $returnObj = [PScustomObject]@{Computer = $ComputerName; Port = $PortNumber; IsOpen = $false}
        }
        $returnObj
    }
    
}#End Test-OpenPorts