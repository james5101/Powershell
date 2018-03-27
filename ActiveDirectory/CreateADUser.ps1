[CmdletBinding()]
param
(
	[parameter(Mandatory = $true)]
	[string]$csvfilepath,
	
	[switch]$IncludeGroups
)
begin
{
	try
	{
		
		Write-Verbose "Attemping to import csv from $csvfilepath"
		$Script:Objects = Import-Csv $csvfilepath -ErrorAction Stop
		Write-Verbose "Imported csv from $csvfilepath  sucesfully"
		
	}
	catch
	{
		Write-Verbose "Failed to import csv from $csvfilepath"
		Write-Warning "Failed to import csv from $csvfilepath "
		return
	}
	
	
}

process
{
	
	
		
		function GetADUser ($SamAccountName , $DomainFQDN)
		{
			
			try
			{
				Write-Verbose "Trying to get user $samaccountname"
				$getuser = Get-Aduser $SamaccountName -server $DomainFQDN
				Write-Verbose "User $samaccountname  already exists" 
				return $true
				
			}
			catch
			{
				Write-Verbose "User $samaccountname does not exist"
				Write-Warning "User $samaccountname  does not exist"
				return $false
			}
		}
		
		function CreateUser ($Givenname, $Surname, $Name, $SamAccountName, $Password, $OUPath, $DomainFQDN, $email)
		{
			if ((Getaduser -samaccountname $SamAccountName -DomainFQDN $DomainFQDN) -eq $true)
			{
				
				Write-Verbose "User $SamAccountName already exists, Not Creating Account"
				return
			}
			else
			{
				Write-Verbose "User $SamAccountName does not exists, Creating Account"
				Write-Warning "User $SamAccountName does not exists, Creating Account"
				$splatting = @{
					'GivenName' = $Givenname;
					'Surname' = $Surname;
					'Name' = $Givenname + " " + $Surname;
					'UserPrincipalName' = $SamAccountName + "@" + $DomainFQDN;
					'SamAccountName' = $SamAccountName;
					'AccountPassword' = (ConvertTo-SecureString $Password -AsPlainText -Force);
					'Path' = $OUPath;
                    'Enabled' = $true;
                    'ChangePasswordAtLogon' = $false;
					'Email' = $Email
					
				}
				$script:splatting
				New-Aduser @splatting
				#SendMail -Email $Email
			}
			
		}
		
		function AddToGroups ($SamAccountName,  $Groups)
		{
			foreach ($group in $Groups)
			{
				try
				{
					Write-Verbose "Adding $group for $SamAccountName"
					Add-AdprincipalGroupMembership -Identity $Samaccount -memberOf $group -ErrorAction Stop
					Write-Verbose "Added $group for $SamAccountName"
				}
				catch
				{
					Write-Verbose "Failed to add $SamAccountName to $group"
					Write-Warning "Failed to add $SamAccountName to $group, Please review"
				}
				
			}
		}
		
		function SendMail ($Email )
		{
			try
			{
				
				
				Write-Verbose "Sent email to $Email with user account details"
			}
			catch
			{
				Write-Verbose "Unable to send email to $Email with user account details"
			}
		}
		
		
	
	$Script:Objects | ForEach-Object{
		
		
		CreateUser -GivenName $_.GivenName -Surname $_.Surname -Name $($GiveName + " " + $Surname) -SamAccountName $_.SamAccountName -Password $_.Password -OUPath $_.OUPath -DomainFQDN $_.DomainFQDN -email $_.Email
		
		if ($PSBoundParameters.ContainsKey('IncludeGroups'))
		{
			AddToGroups -SamAccountName $_.SamAccountName -Groups $_.Groups
		}
	}
	
	
	
}








