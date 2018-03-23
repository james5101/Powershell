Import-Module pester 
Describe "AzureRm ARM Templates"{
    it "Converts from JSON and has the expected properties" {
             $expectedProperties = '$schema',
                                  'contentVersion',
                                  'parameters',
                                  'variables',
                                  'resources',                                
                                  'outputs' | Sort-Object
                $templateProperties = (get-content "$PSScriptRoot\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | Sort-Object -Property NoteProperty | foreach Name
                $templateProperties | Should Be $expectedProperties
        }

    It "Has parameters file" {        
            "$PSScriptRoot\azuredeploy.parameters*.json" | Should Exist
    }
}

Describe "AzureRm ARM Resources"{
    It "Creates the correct resources" {
    $expectedResources = "Microsoft.Network/networkInterfaces","Microsoft.Compute/virtualMachines","Microsoft.Compute/virtualMachines/extensions"
    $templateResources = (get-content "$PSScriptRoot\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
    $templateResources | Should Be $expectedResources
    }

    It "Creates the correct number resources" {
    $expectedResources = '3'
    $templateResources = (get-content "$PSScriptRoot\azuredeploy.json" | ConvertFrom-Json -ErrorAction SilentlyContinue).Resources.type
    $templateResources.count | Should Be $expectedResources
    }
       

}
