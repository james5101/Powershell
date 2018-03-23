function AuthVsts 
{
    [CmdletBinding()]
    param(
    <#
        .SYNOPSIS 
        This function is a helper function to authenticate to VSTS. We take a PAT token and encode it to Base64
        .EXAMPLE
        AuthVsts -vstsAccount "blabla" -projectName "Infra" -token "PAT TOKEN GOES HERE" -user "". We leave user blank
    #>
        [Parameter(HelpMessage = "VSTS Account goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$vstsAccount,

        [Parameter(HelpMessage = "VSTS project goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$projectName, 

        
        [Parameter(HelpMessage = "VSTS Account Token Goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$token,

        [Parameter(HelpMessage = "VSTS User Account goes here, Default is blank,not sure why we need this :)")]
        [ValidateNotNullOrEmpty()]
        $user = ""
    )
    #Base64-encodes the Personal Access Token (PAT) appropriately
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
    
    return "Basic {0}" -f $base64AuthInfo

}

function GetVstsBuildDefinitions
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
    <#
        .SYNOPSIS 
        This function is a helper function to authenticate to get current Vsts Build definitions. It reutrns a pscustomobject of the build definition name and the ID number
        .EXAMPLE
        GetVstsBuildDefinitions -vstsAccount "blabla" -projectName "Infra"
     
    #>
        [Parameter(HelpMessage = "VSTS Account goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$vstsAccount,

        [Parameter(HelpMessage = "VSTS project goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$projectName,

        [Parameter(HelpMessage = "VSTS Account Token Goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$token
    )

    $authvsts = AuthVsts -vstsAccount $vstsAccount -projectName $projectName -token $token
    $uri = "https://$($vstsAccount).visualstudio.com/DefaultCollection/$($projectName)/_apis/build/definitions?api-version=2.0"
    try{
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=($authvsts)} -ErrorAction Stop
        
        $object = $response.value | ForEach-Object {[PSCustomObject]@{Name = $_.Name; ID = $_.ID}}
        return $object
        

        
    }
    catch{
        Write-Warning "Encountered Error :$($_.Exception.Message)"
    }
}


#not working
<#function GetLast25BuildsForDefinition
{
    Param(
       [string]$vstsAccount,
       [string]$projectName,
       [string]$user = "",
       [string]$token 
    )
    #Base64-encodes the Personal Access Token (PAT) appropriately
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
    $uri = "https://.visualstudio.com/DefaultCollection//_apis/build/builds?definitions=25&statusFilter=completed&`$top=1&api-version=2.0"

    try{
        $response = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -ErrorAction Stop
        $result = $response 
        return $result
    }
    catch{
    }
        
}#>
function QueueBuild
{
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium")]
    
    param(
    <#
        .SYNOPSIS 
        This function is a  function to queue a new build based on a vsts build definition name. In order to to queue a build we need to POST to the Vsts api. We need to construct a body, which leverages the GetVstsBuildDefinitions Helper function. We need to pass the api the Build DefinitionID.
        .EXAMPLE
        QueueBuild -vstsAccount "blabla" -projectName "Infra" -BuildDefinitionName "SF.Build"
     
    #>
        [Parameter(HelpMessage = "VSTS Account goes here'")]
        [ValidateNotNullOrEmpty()]
        [string]$vstsAccount,

        [Parameter(HelpMessage = "VSTS project goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$projectName,

        [Parameter(HelpMessage = "VSTS Account Token Goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$token,

        [Parameter(HelpMessage = "Build definition Name goes here")]
        [ValidateNotNullOrEmpty()]
        [string]$BuildDefinitionName

    )
    $authvsts =  AuthVsts -vstsAccount $vstsAccount -projectName $projectName -token $token
    $uri = "https://$($vstsAccount).visualstudio.com/DefaultCollection/$($projectName)/_apis/build/builds?api-version=2.0"
    $buildDefinitonID = GetVstsBuildDefinitions | Where-Object {$_.Name -like $BuildDefinitionName} | Select-Object -ExpandProperty ID
    $hash = @{
        Id = $buildDefinitonID
    }
    $jsonBody = $hash | ConvertTo-Json

    

    if ($PSCmdlet.ShouldProcess("You are about to queue a build, be careful and godspeed"))
    {
       $buildresponse = Invoke-RestMethod -Method Post -ContentType application/json -Uri $Uri -Headers @{Authorization=($authvsts)} -Body $jsonBody 
    }
        
    
        
}



<# Dont really need, keeping for reference
function GetVstsBuildID
{
    $buildID = $buildResponse.Id
    $url = "https://.visualstudio.com/DefaultCollecti-infra/_apis/build/builds/"+$buildID+"?api-version=2.0"

    $buildResponse.Id = @{
        Authorization = (NewAuthToken)
    }

    return Invoke-RestMethod -Method Get -Uri $url -UseBasicParsing -Headers $buildResponse.Id
}#>