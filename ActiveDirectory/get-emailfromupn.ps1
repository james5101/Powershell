
function Get-EmailFromUpn
{
	param
	(
		[parameter(Mandatory = $true)]
		[string]
		$csvfilepath
	)
	[CMdletBinding[]]
	
	$importObjs = Import-Csv -Path $csvfilepath
	
	$importObjs | ForEach-Object{
		
		$upn = $_.Upn
		try{ $getuser = $true; $getprops = Get-ADUser -Properties * -Filter { UserPrincipalName -eq $upn } -ErrorAction Stop }
		catch { $getuser = $false;  $getusererror = $Error.Exception.Message}
		if ($getuser -eq $true)
		{
			[PSCustomObject]@{ user = $getprops.userprincipalname; email = $getprops.emailaddress }
		}
		else
		{
			[PSCustomObject]@{ Error = $getusererror }
		}
		
	}
}
Get-OCCMEmailFromUpn