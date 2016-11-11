Configuration dscDomainJoin
{
    param(
        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
        [string[]]$ComputerName="localhost"
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xComputerManagement    
    Import-DscResource -ModuleName xActiveDirectory

    $domainName = Get-AutomationVariable -Name 'domainName'
    $domainCreds = Get-AutomationPSCredential -Name 'domainCreds'

    Node $AllNodes.NodeName
    {
        WindowsFeature ADPowershell
        {
            Name                 = "RSAT-AD-PowerShell"
            Ensure               = "Present"
        } 

        xComputer JoinDomain
        {
            Name                 = $ComputerName
            DomainName           = $domainName
            JoinOU               = "OU=PRD,OU=allServers,OU=allMachines,DC=ad,DC=rockend,DC=io"
            Credential           = $domainCreds
        }
    }
}
