configuration ActiveDirectory
{

[CmdletBinding()]

Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory

Param (
	[string] $NodeName = "PrimaryDomainController",
	[string] $domainName = "rockend.io",
	[System.Management.Automation.PSCredential]$domainAdminCredentials
)

	Node PrimaryDomainController
    {
        LocalConfigurationManager
		{
			ConfigurationMode = 'ApplyAndAutoCorrect'
			RebootNodeIfNeeded = $true
			ActionAfterReboot = 'ContinueConfiguration'
			AllowModuleOverwrite = $true
		}

		WindowsFeature DNS_RSAT
		{ 
			Ensure = "Present" 
			Name = "RSAT-DNS-Server"
		}

		WindowsFeature ADDS_Install 
		{ 
			Ensure = 'Present' 
			Name = 'AD-Domain-Services' 
		} 

		WindowsFeature RSAT_AD_AdminCenter 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-AdminCenter'
		}

		WindowsFeature RSAT_ADDS 
		{
			Ensure = 'Present'
			Name   = 'RSAT-ADDS'
		}

		WindowsFeature RSAT_AD_PowerShell 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-PowerShell'
		}

		WindowsFeature RSAT_AD_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-AD-Tools'
		}

		WindowsFeature RSAT_Role_Tools 
		{
			Ensure = 'Present'
			Name   = 'RSAT-Role-Tools'
		}      

		WindowsFeature RSAT_GPMC 
		{
			Ensure = 'Present'
			Name   = 'GPMC'
		} 
		xADDomain CreateForest 
		{ 
			DomainName = $domainName            
			DomainAdministratorCredential = $domainAdminCredentials
			SafemodeAdministratorPassword = $domainAdminCredentials
			DatabasePath = "C:\Windows\NTDS"
			LogPath = "C:\Windows\NTDS"
			SysvolPath = "C:\Windows\Sysvol"
			DependsOn = '[WindowsFeature]ADDS_Install'
		}
    }
}
