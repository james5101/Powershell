function GenerateCertAndNewAzureRmSP
{

    Param (

     # Use to set subscription. If no value is provided, default subscription is used. 
     [Parameter(Mandatory=$false)]
     [String] $SubscriptionId,

     [Parameter(Mandatory=$true)]
     [String] $ApplicationDisplayName,

     [Parameter(Mandatory=$true)]
     [String] $CertSubjectName
     )

     #Login-AzureRmAccount
     Import-Module AzureRM.Resources

     if ($SubscriptionId -eq "") 
     {
        $SubscriptionId = (Get-AzureRmContext).Subscription.Id
     }
     else
     {
        Set-AzureRmContext -SubscriptionId $SubscriptionId
     }

     
     if (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $CertSubjectName })
     {
        Write-Warning "Cert with subject name $($CertSubjectName) already exists...Not generating cert"
     }
     else
     {
        Write-Verbose "Generating cert with subject name of $($CertSubjectName)"
        $cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject $CertSubjectName -KeySpec KeyExchange
        $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
     }

     if (Get-AzureRmADServicePrincipal -SearchString $ApplicationDisplayName)
     {
        Write-Warning "Service Principal with $($ApplicationDisplayName) already exists...Exiting"
     }
     else
     {
         $ServicePrincipal = New-AzureRMADServicePrincipal -DisplayName $ApplicationDisplayName -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore
         Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id 

         $NewRole = $null
         $Retries = 0;
         While ($NewRole -eq $null -and $Retries -le 6)
         {
            # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
            Sleep 15
            New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ServicePrincipal.ApplicationId  | Write-Verbose -ErrorAction SilentlyContinue
            $NewRole = Get-AzureRMRoleAssignment -ObjectId $ServicePrincipal.Id -ErrorAction SilentlyContinue
            $Retries++;
         }
     }
}

function GetCertThumbPrint
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    Param (

     [Parameter(Mandatory=$true)]
     [ValidatePattern("^cn=")]
     [String] $CertSubjectName
     )

     $Thumbprint = (Get-ChildItem cert:\CurrentUser\My\ | Where-Object {$_.Subject -match $CertSubjectName }).Thumbprint
     if ($Thumbprint)
     {
        [PSCustomObject]@{Thumbprint = $Thumbprint}
     }
     else
     {
        [PSCustomObject]@{Thumbprint = "N/A"}
     }
}

function GetApplicationid
{
    Param (

     [Parameter(Mandatory=$true)]
     [String] $ApplicationDisplayName
     )

     $ApplicationId = Get-AzureRmADServicePrincipal -SearchString $ApplicationDisplayName 

     [PSCustomObject]@{ApplicationId = $ApplicationId.ApplicationId.Guid}
}

function LoginServicePrincipal
{
    Param (

     [Parameter(Mandatory=$true)]
     [String] $CertSubjectName,
     [Parameter(Mandatory=$true)]
     [String] $ApplicationDisplayName
     )

    $Cert = (GetCertThumbPrint -CertSubjectName $CertSubjectName).thumbprint
    $applicationid = (GetApplicationid -ApplicationDisplayName $ApplicationDisplayName).ApplicationId
    $tenantid = Get-AzureRmContext

    Login-AzureRmAccount -ServicePrincipal -CertificateThumbprint $Cert -ApplicationId $applicationid -TenantId $tenantid.Tenant.TenantId

}
