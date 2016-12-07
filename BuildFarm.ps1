configuration BuildFarm
{ 
    Import-DscResource -Name MSFT_xServiceResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName AzureRM.KeyVault
    Import-DscResource -Module cNtfsAccessControl
    Import-DscResource -Module xPSDesiredStateConfiguration
    Import-DSCResource -ModuleName SlackDSCResource
    Import-DscResource -Module xComputerManagement
    
    #param for keyvault = svcSonarQubeDB
    $domainCredentials = Get-AutomationPSCredential -Name 'domainCreds'
    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'
    $sonarQubeCredential = Get-AutomationPSCredential -Name 'svcSonarQubeDB'
    $slackToken = Get-AutomationVariable -Name 'slackToken'

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

    Node Klondike
    {
        File Klondike
        {
            DestinationPath = "c:\inetpub\wwwroot"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\klondike\RElease\Klondike-Release-master"
    		Type = "Directory"
    		Recurse = $true
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }

    Node TeamCity
    {
        File TeamCity
        {
            DestinationPath = "c:\software\Jetbrains\TeamCity"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\TeamCity\TeamCity-10.0.2.exe"
    		Type = "File"
    		Recurse = $false
        }
        
        File sqljdbc
        {
            DestinationPath = "c:\software\Microsoft\sqljdbc"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\TeamCity\sqljdbc_4.2.6420.100_enu.exe.lnk"
    		Type = "File"
    		Recurse = $false
        }
        
        #Install c:\software\Microsoft\sqljdbc\sqljdbc_4.2.6420.100_enu.exe (depends on copy jobs)
        #Install c:\software\TeamCity-10.0.2.exe (depends on previous and copy jobs)
        
        #Copy "S:\Software\TeamCity\Config\*.*" to F:\TeamCityData\config (depends on all previous)
        #Copy S:\Software\TeamCity\Plugins\*.* to F:\TeamCityData\plugins
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }

    Node SonarQube
    {   
        Environment slackToken
        {
            Ensure = "Present"
            Name = "slackToken"
            Value = "$slackToken"
        }
        Script SlackMessage
        {
            GetScript = {
                    #worked twice in here
                return $env:COMPUTERNAME
            }
            TestScript = {
                $ServiceStatus = (get-service SonarQube).status
                Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body @{
                    token    = $env:slackToken
                    channel  = "@david.niwczyk"
                    username = "Azure DSC"
                    text     = "$("SonarQube service is") $($ServiceStatus) $("on") $($env:COMPUTERNAME)"
                }
                $computerName = $GetScript
                if ( $computerName )
                {
                    return $true
                }
                return $false
            }
            SetScript = {
                Write-Verbose -Message ('ComputerName doesnt exist')
            }
            DependsOn = "[Environment]slackToken"
                      
        }
        
    	File SonarQube
    	{
    		DestinationPath         = "C:\sonarqube-6.0\sonarqube-6.0"
    		Credential              = $storageCredential
    		Ensure                  = "Present"
    		SourcePath              = "\\prodrockcoresoftware.file.core.windows.net\software\Software\SonarQube\sonarqube-6.0\sonarqube-6.0"
    		Type                    = "Directory"
    		Recurse                 = $true
     	}
        
        File sqljdbc
    	{
    		DestinationPath     = "C:\Windows\System32"
    		Credential          = $storageCredential
    		Ensure              = "Present"
    		SourcePath          = "\\prodrockcoresoftware.file.core.windows.net\software\Software\sqlJDBC\Microsoft JDBC Driver 4.2 for SQL Server\sqljdbc_4.2\enu\auth\x64"
    		Type                = "Directory"
    		Recurse             = $true
            DependsOn           = "[File]SonarQube"
     	}
        
        File SonarQubePlugins
    	{
    		DestinationPath     = "C:\sonarqube-6.0\sonarqube-6.0\extensions\plugins"
    		Credential          = $storageCredential
    		Ensure              = "Present"
    		SourcePath          = "\\prodrockcoresoftware.file.core.windows.net\software\Software\SonarQube\plugins"
    		Type                = "Directory"
    		Recurse             = $true
            DependsOn           = "[File]SonarQube"
     	}
        
        #Run "c:\sonarqube-6.0\sonarqube-6.0\bin\windows-x86-64\InstallNTService.bat"
        #Machine needs to restart to refresh service
        
        #Copy JDK install from storage account
        File JDK
    	{
    		DestinationPath     = "C:\software\Java\JDK"
    		Credential          = $storageCredential
    		Ensure              = "Present"
    		SourcePath          = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Jdk1.8\"
    		Type                = "Directory"
    		Recurse             = $true
     	}

        Package JDK
        {
            Ensure              = "Present"
            Path                = "$Env:SystemDrive\software\Java\JDK\jdk-8u101-windows-x64.exe"
            Name                = "Java SE Development Kit 8 Update 101 (64-bit)"
            ProductId           = "64A3A4F4-B792-11D6-A78A-00B0D0180101"
            DependsOn           = "[File]JDK"
        }

        Environment JavaPath
        {
            Name                = 'Path'
            Ensure              = 'Present'
            Path                = $true
            Value               = 'C:\Program Files\Java\jdk1.8.0_101\bin'
            DependsOn           = '[Package]JDK'
        }
        
        cNtfsPermissionEntry svcSonarQubeDbPermission
        {
            Ensure              = 'Present'
            Path                = 'C:\sonarqube-6.0\'
            Principal           = 'svcSonarQubeDb@cloud.rockend.io'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
            DependsOn           = '[File]SonarQube'
        }
        
        Service SonarQubeNew
        {
            Name                = 'SonarQube'
            DisplayName         = 'SonarQube'
            StartupType         = 'Automatic'
            Credential          = $sonarQubeCredential
            State               = 'Running'
            Ensure              = "Present"
            Path                = 'C:\sonarqube-6.0\sonarqube-6.0\bin\windows-x86-64\wrapper.exe -s C:\sonarqube-6.0\sonarqube-6.0\conf\wrapper.conf'
            DependsOn           = '[cNtfsPermissionEntry]svcSonarQubeDbPermission'
        }
        Service SonarQubeStart
        {
            Name                = "SonarQube"
            DisplayName         = 'SonarQube'
            StartupType         = "Automatic"
            State               = "Running"
            Credential          = $sonarQubeCredential
            DependsOn           = '[Service]SonarQubeNew'
        } 
        
        LocalConfigurationManager 
        { 
            CertificateId = $node.Thumbprint 
        }

        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node NotWebServer
    {
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }

}
