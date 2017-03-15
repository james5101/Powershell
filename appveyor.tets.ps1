ipmo Pester


Describe Import Module{
    Import-Module .\MSMQQueueManagerQuota.psm1 | should not throw
}