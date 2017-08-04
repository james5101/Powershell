
ipmo Pester


Describe "Import Module"{
    It "Imports" {
    {Import-Module .\MSMQQueueManagerQuota.psm1} | Should Not throw
    }
}    
