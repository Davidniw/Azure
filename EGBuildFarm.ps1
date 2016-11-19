configuration BuildFarm
{ 
    Import-DscResource -Name MSFT_xServiceResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName AzureRM.KeyVault

    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'


    Node JumpBox
    {
        WindowsFeature RDSGateway
        {
            Ensure  = "Present"
            Name    = "RDS-Gateway"
            IncludeAllSubFeature = $true
        }
        
        WindowsFeature IIS6ManagementConsole
        {
            Ensure  = "Present"
            Name    = "Web-Lgcy-Mgmt-Console"
            IncludeAllSubFeature = $true
        }
        
        WindowsFeature ADDAandADLDSTools 
        {
            Ensure  = "Present"
            Name    = "RSAT-AD-Tools"
            IncludeAllSubFeature = $true
        }
        
        WindowsFeature RemoteDesktopGatewayTools 
        {
            Ensure  = "Present"
            Name    = "RSAT-RDS-Gateway"
            IncludeAllSubFeature = $true
        }
        
        WindowsFeature NetworkPolicyandAccessServicesTools 
        {
            Ensure  = "Present"
            Name    = "RSAT-NPAS"
            IncludeAllSubFeature = $true
        }
    }

    Node TeamCity
    {
        File TeamCity
        {
            DestinationPath = "c:\software\Jetbrains\TeamCity"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodevgcoresoftware.file.core.windows.net\software\Software\TeamCity\TeamCity-10.0.2.exe"
            Type = "File"
            Recurse = $false
        }
        
        File sqljdbc
        {
            DestinationPath = "c:\software\Microsoft\sqljdbc"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodevgcoresoftware.file.core.windows.net\software\Software\TeamCity\sqljdbc_4.2.6420.100_enu.exe.lnk"
            Type = "File"
            Recurse = $false
        }
        
        File BuildTools2013
        {
            DestinationPath = "c:\software\Microsoft\BuildTools"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodevgcoresoftware.file.core.windows.net\software\Software\TeamCity\BuildTools_2013_Full.exe"
            Type = "File"
            Recurse = $false
        }
        
        File BuildTools2015
        {
            DestinationPath = "c:\software\Microsoft\BuildTools"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodevgcoresoftware.file.core.windows.net\software\Software\TeamCity\BuildTools_2015_Full.exe"
            Type = "File"
            Recurse = $false
        }

        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
}
