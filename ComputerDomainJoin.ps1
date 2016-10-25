configuration ComputerDomainJoin
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xDSCDomainjoin'

    $dscDomainAdmin = Get-AutomationPSCredential -Name 'domainCreds'
    $dscDomainName = Get-AutomationVariable -Name 'dscDomainName'
 
    Node DomainJoin
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $dscDomainName
            Credential = $dscDomainAdmin
        }
    }
}
