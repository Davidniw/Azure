Configuration dscDomainJoin
{
    param(
        [Int]$RetryCount = 20,
        [Int]$RetryIntervalSec = 30
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
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        } 

        xWaitForADDomain WaitForDomain 
        { 
            DomainName = $domainName 
            DomainUserCredential= $domainCreds
            RetryCount = $RetryCount 
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[WindowsFeature]ADPowershell" 
        }

        xComputer JoinDomain
        {
            Name = 'PRIVVMSNQAPE03'
            DomainName = $domainName
            Credential = $domainCreds
            DependsOn = "[xWaitForADDomain]WaitForDomain" 
        }
    }
}
