configuration BuildFarm
{ 

    Import-DscResource -Name MSFT_xServiceResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName AzureRM.KeyVault
    Import-DscResource -Module cNtfsAccessControl
    Import-DscResource -Module xPSDesiredStateConfiguration
    Import-DSCResource -ModuleName SlackDSCResource
    Import-DscResource -Module xComputerManagement
    Import-DscResource -module xChrome 
    Import-DscResource -module xDSCDomainjoin
    
    #param for keyvault = svcSonarQubeDB
    $domainCredentials = Get-AutomationPSCredential -Name 'domainCreds'
    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'
    $sonarQubeCredential = Get-AutomationPSCredential -Name 'svcSonarQubeDB'
    $slackToken = Get-AutomationVariable -Name 'slackToken'
    $domainName = Get-AutomationVariable -Name 'domainName'

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
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=KDK,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
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

    Node TeamCityServer
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=TCS,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
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
        
        File NodeJS
        {
            DestinationPath = "c:\software\Joyent\NodeJS"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Utilities\NodeJS\node-v6.9.1-x64.msi"
    		Type = "Directory"
    		Recurse = $false
        }
        
        File Git
        {
            DestinationPath = "c:\software\Git\Git"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\\software\Utilities\Git\Git-2.11.0-64-bit.exe"
    		Type = "Directory"
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
    
    Node TeamCityAgent
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=TCA,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
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
        
        File NodeJS
        {
            DestinationPath = "c:\software\Joyent\NodeJS"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Utilities\NodeJS"
    		Type = "Directory"
    		Recurse = $false
        }
        
        File Git
        {
            DestinationPath = "c:\software\Git\Git"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\\software\Utilities\Git"
    		Type = "Directory"
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
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=SNQ,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        Environment slackToken
        {
            Ensure = "Present"
            Name = "slackToken"
            Value = "$slackToken"
        }
        
        Script SlackMessage
        {   
            GetScript = { }
            TestScript = { $false }
            SetScript = {
                $ServiceStatus = (get-service SonarQube).status
                Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -Body @{
                    token    = $env:slackToken
                    channel  = "@david.niwczyk"
                    username = "Azure DSC"
                    text     = "$("SonarQube service is") $($ServiceStatus) $("on") $($env:COMPUTERNAME)"
                }
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
            DependsOn           = '[xDSCDomainjoin]JoinDomain'
        }
        
        Service SonarQube
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
        
             
        MSFT_xChrome chrome 
        { 
            Language = "English" 
            LocalPath = "C:\Program Files (x86)\Google\Chrome\Application"
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
    
    Node Backup
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=BCK,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node RabbitMQ
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=SM,OU=allProducts,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node APIServer
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=SM,OU=allProducts,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node Octopus
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=OCT,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node sqlServer
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=SQL,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }
        
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }
    
    Node PrimaryDomainController
    {

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
		
    }

	Node BackupDomainController
    {

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
