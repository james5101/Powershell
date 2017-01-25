<#
.Synopsis
   Unamange single or multiple nodes from SW
.DESCRIPTION
   Long description
.EXAMPLE
   Unmanage-Node -ComputerName 'computername' -Cred Username -MinutesToUnManage 60 -Verbose
.EXAMPLE
   gc C:\Users\username\Desktop\mycomps.txt | Unmanage-Node -Cred username -MinutesToUnManage 60 -Verbose
.EXAMPLE 
    Unmanage-SWNode -ComputerName (gc C:\Users\username\Desktop\mycomps.txt) -Cred username -Verbose
.NOTES
	THIS REQUIRES INSTALL OF THE SWISSNAPIN
		https://github.com/solarwinds/OrionSDK
#>
#Requires -PSSnapin SwisSnapin
function Unmanage-SWNode
{
    [CmdletBinding()]
    Param
    (
       [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('CN','Name')]
        [String[]]
        $ComputerName,

        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.CredentialAttribute()]
        $Cred,

        [Parameter(
            Position = 2
        )]
        [ValidateNotNullOrEmpty()]
        $MinutesToUnManage = 60

    )

    Begin
    {
        if (! (Get-PSSnapin | where {$_.Name -eq "SwisSnapin"})) 
        {
            Add-PSSnapin "SwisSnapin"
        }

        $hostname = "dc4-ocp-m-ul06.onecallmedical.com"
        $swis = Connect-Swis -Hostname $hostname -Credential $cred 
        $now = [DateTime]::UtcNow
        $later = $now.AddMinutes($MinutesToUnManage)
        
    }
    Process
    {
        $ComputerName | 
            ForEach-Object -Process {
                $Comp = $_
                $strQuery = "SELECT NodeID FROM Orion.Nodes WHERE SysName LIKE '" + "$Comp" + "%'"
                Write-Verbose "Getting SW Data on $Comp"
                $NodeID = Get-SwisData $swis $strQuery 
                
                
                
                
                if ($NodeID)
                {
                    Write-Verbose "Unamanaging SW on $Comp at $now"
	                Invoke-SwisVerb $swis Orion.Nodes Unmanage @("N:$NodeID", $now, $later, "false") | Out-Null
                    $returnObj = New-Object psobject -Property @{Computer = $Comp; Unmanaged = $true; InSolarWinds = $true}
                }
                else
                {
                    Write-Verbose "Can Not Find $Comp in SW"
                    $returnObj = New-Object psobject -Property @{Computer = $Comp; Unmanaged = $false; InSolarWinds = $false}
                }
               $returnObj
            }
            
    }
    End
    {
    }
}

Unmanage-SWNode -ComputerName (gc $PSScriptRoot\UnmanageComps.txt) -Cred "$ENV:USERNAME" -MinutesToUnManage 60