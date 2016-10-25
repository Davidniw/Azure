Configuration dscDomainJoin
{
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
        
        xComputer DomainJoin
        {
            Name = $Node.NodeName
            DomainName = $domainName
            Credential = $domainCreds
            DependsOn = "[WindowsFeature]ADPowershell" 
        }
    }
}
