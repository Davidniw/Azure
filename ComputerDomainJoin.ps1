Configuration ComputerDomainJoin
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'xDSCDomainjoin'
    $dscDomainAdmin = Get-AutomationPSCredential -Name 'dscDomainAdmin'
    $dscDomainName = Get-AutomationVariable -Name 'dscDomainName'
 
    node DomainJoin
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $dscDomainName
            Credential = $dscDomainAdmin
        }
    }
}