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
    Import-DscResource -ModuleName cChoco

    #param for keyvault = svcSonarQubeDB
    $domainCredentials = Get-AutomationPSCredential -Name 'domainCreds'
    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'
    $sonarQubeCredential = Get-AutomationPSCredential -Name 'svcSonarQubeDB'
    $sqlServerLocalAdminCredential = Get-AutomationPSCredential -Name 'sqlServerLocalAdmin'

    $domainName = Get-AutomationVariable -Name 'domainName'

    Node JumpBox
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=JMP,OU=allCore,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
        }

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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
         Name        = "googlechrome"
         DependsOn   = "[cChocoInstaller]installChoco"
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
            DestinationPath = "c:\software\Jetbrains\TeamCity\TeamCity-10.0.2.exe"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\TeamCity\TeamCity-10.0.2.exe"
            Type = "File"
            Recurse = $false
        }

        File sqljdbc
        {
            DestinationPath = "c:\software\Microsoft\sqljdbc\sqljdbc_4.2.6420.100_enu.exe.lnk"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\TeamCity\sqljdbc_4.2.6420.100_enu.exe.lnk"
            Type = "File"
            Recurse = $false
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
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

    Node TeamCityAgentFull
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=TCA,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
        }

        cChocoPackageInstaller installGit
        {
            Ensure = 'Present'
            Name = "git"
            #Params = ""
        }

        File MSBuildTools14
        {
            DestinationPath = "c:\software\Microsoft\Build Tools\BuildTools_Full.exe"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Microsoft\Microsoft Build Tools 2015\BuildTools_Full.exe"
            Type = "File"
            Recurse = $false
        }
        
        Package installMSBuildTools14
        {
            Ensure              = "Present"
            Path                = "c:\software\Microsoft\Build Tools\BuildTools_Full.exe"
            Name                = "Microsoft Build Tools 14.0 (amd64)"
            ProductId           = "8C918E5B-E238-401F-9F6E-4FB84B024CA2"
            Arguments           = "/q"
            DependsOn           = "[File]MSBuildTools14"
        }
        cChocoPackageInstaller installMSBuildTools12
        {
            Ensure = 'Present'
            Name = "microsoft-build-tools"
            Version = "12.0.21005.1"
        }

        cChocoPackageInstaller NodeJS
        {
            Ensure = 'Present'
            Name = "nodejs.install"
            #Params = ""
        }

        cChocoPackageInstaller Redis
        {
            Ensure = 'Present'
            Name = "redis-64"
            #Params = ""
        }
        
        cChocoPackageInstaller JavaRuntimeEnvironment
        {
            Ensure = 'Present'
            Name = "server-jre"
        }

        File AzureBuildTools
        {
            DestinationPath = "c:\software\Microsoft\Azure Build Tools"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Microsoft\Azure Build Tools"
            Type = "Directory"
            Recurse = $true
        }
        
        File SQLEXPR
        {
            DestinationPath = "c:\software\Microsoft\SQL\SQLEXPR_x64_ENU.exe"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Microsoft\SQL\SQLEXPR_x64_ENU.exe"
            Type = "File"
            Recurse = $false
        }

        Package AzureLibsForNet
        {
            Ensure              = "Present"
            Path                = "c:\software\Microsoft\Azure Build Tools\WindowsAzureLibsForNet-x64.msi"
            Name                = "Windows Azure Libraries for .NET – v2.3"
            ProductId           = "C0591F2A-45AD-4189-86A7-C2B1DF3D148D"
            DependsOn           = @("[File]AzureBuildTools","[Package]installMSBuildTools14")
        }

        Package AzureAuthoringTools
        {
            Ensure              = "Present"
            Path                = "c:\software\Microsoft\Azure Build Tools\WindowsAzureAuthoringTools-x64.msi"
            Name                = "Windows Azure Authoring Tools - v2.3"
            ProductId           = "CA53F7A1-A71D-4C7F-ABD2-7BDD26FE0D74"
            DependsOn           = @("[File]AzureBuildTools","[Package]AzureLibsForNet")
        }

        Package WindowsAzureTools
        {
            Ensure              = "Present"
            Path                = "c:\software\Microsoft\Azure Build Tools\WindowsAzureTools.vs120.exe"
            Name                = "Windows Azure Tools for Microsoft Visual Studio 2013 - v2.3"
            ProductId           = "E055B52B-39C5-4AA9-BD7C-05CC5D1774B7"
            Arguments           = "/q"
            DependsOn           = @("[File]AzureBuildTools","[Package]AzureAuthoringTools")
        }
        
        Script DownloadBuildAgent
        {   
            GetScript = { }
            TestScript = { return (Test-Path C:\buildAgent.zip) }
            SetScript = {
                    $url = 'http://teamcity.cloud.rockend.io/update/buildagent.zip'
                    $wc = New-Object System.Net.WebClient
                    $output = 'c:\buildagent.zip'
                    $wc.DownloadFile($url, $output)
                }
        }

        Script ExtractBuildAgent
        {   
            GetScript = { }
            TestScript = { return (Test-Path C:\buildAgent) }
            SetScript = {
            <# NEED TRY CATCH TO ENSURE ZIP FILE ISN'T CURRUPT #>
                    $output = 'c:\buildagent.zip'
                    $agentDir = 'C:\buildAgent'
                    Add-Type -assembly “system.io.compression.filesystem”
                    [io.compression.zipfile]::ExtractToDirectory($output, $agentDir)
                }
             Dependson = "[Script]DownloadBuildAgent"
        }
        Script ConfigureBuildAgent
        {   
            GetScript = { }
            TestScript = { return (Test-Path C:\buildAgent\conf\buildAgent.properties) }
            SetScript = {
                    $serverUrl = 'http://teamcity.cloud.rockend.io'
                    $agentDir = 'C:\buildAgent'
                    $agentName = $env:COMPUTERNAME
                    $ownPort = '9090'

                    # Configure agent
                    copy $agentDir\conf\buildAgent.dist.properties $agentDir\conf\buildAgent.properties
                    (Get-Content $agentDir\conf\buildAgent.properties) | Foreach-Object {
                        $_ -replace 'serverUrl=http://localhost:8111/', "serverUrl=$serverUrl" `
                         -replace 'name=', "name=$agentName" `
                         -replace 'ownPort=9090', "ownPort=$ownPort"
                        } | Set-Content $agentDir\conf\buildAgent.properties
                }
            Dependson = "[Script]ExtractBuildAgent"
        }
        
        Environment Git-nodejs
        {
            Ensure = "Present"
            Name = "Path"
            Path = $true
            Value = "C:\Program Files\Git\cmd;C:\Program Files\nodejs\"
        }
        
        cNtfsPermissionEntry svcTeamCityAgentPermission
        {
            Ensure              = 'Present'
            Path                = 'C:\buildAgent\'
            Principal           = 'svcTeamCityAgent@cloud.rockend.io'
            AccessControlInformation = @(
                cNtfsAccessControlInformation
                {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'Modify'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false
                }
            )
        }
        
        Service TeamCityBuildAgent
        {   
            DisplayName           = 'TeamCity Build Agent'
            Name                  = 'TCBuildAgent'
            StartupType           = 'Automatic'
            State                 = 'Running'
            Credential            = $svcTeamCityAgent
            Path                  = 'C:\buildAgent\launcher\bin\TeamCityAgentService-windows-x86-32.exe -s C:\buildAgent\launcher\conf\wrapper.conf'
            DependsOn             = @("[Script]ConfigureBuildAgent","[cNtfsPermissionEntry]svcTeamCityAgentPermission")
        }
        
        Script StartTeamCityAgentService
        {   
            GetScript = { 
                # Do Nothing
            }
            TestScript = { 
                return ((Get-WmiObject -class Win32_Service -filter "name='TCBuildAgent'" -ErrorAction SilentlyContinue).state -eq 'Running')
            }
            SetScript = {
                Start-Service TCBuildAgent
            }
        }
        
        Script ExtractSQLEXPR
        {   
            GetScript = { 
                # Do Nothing
            }
            TestScript = { 
                return (Test-Path c:\software\Microsoft\SQL\SQLEXPR_x64_ENU\setup.exe)
            }
            SetScript = {
                & "c:\software\Microsoft\SQL\SQLEXPR_x64_ENU.exe" /x:"c:\software\Microsoft\SQL\SQLEXPR_x64_ENU\" /u
            }
            DependsOn = "[File]SQLEXPR"
        }
        
        File AzureStorageEmulator
        {
            DestinationPath = "c:\software\Microsoft\Azure Storage Emulator\MicrosoftAzureStorageEmulator.msi"
            Credential = $storageCredential
            Ensure = "Present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Microsoft\Azure Storage Emulator\MicrosoftAzureStorageEmulator.msi"
            Type = "File"
            Recurse = $false
        }
        
        File AzureStorageEmulatorScheduledTask
        {
            DestinationPath = "C:\software\Microsoft\Azure Storage Emulator.xml"
            Credential = $storageCredential
            Ensure = "present"
            SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\Microsoft\Azure Storage Emulator\Azure Storage Emulator.xml"
            Type = "File"
            Recurse = $false
        }
        
        Package AzureStorageEmulator
        {
            Ensure              = "Present"
            Path                = "$Env:SystemDrive\software\Microsoft\Azure Storage Emulator\MicrosoftAzureStorageEmulator.msi"
            Name                = "Microsoft Azure Storage Emulator - v4.5"
            ProductId           = "54277EE5-C729-4002-B3E2-0E78B3EF3F3E"
            DependsOn           = "[File]AzureStorageEmulator"
        }

        Package SQLExpress
        {
            Ensure = 'Present'
            Name = 'Microsoft SQL Server 2014 Setup (English)'
            Path = 'c:\software\Microsoft\SQL\SQLEXPR_x64_ENU\Setup.exe'
            ProductId = '0EEBDCCA-EF5D-4896-9FEA-D7D410A57E8A'
            Arguments = '/ACTION=Install /Q /IACCEPTSQLSERVERLICENSETERMS /INSTANCENAME="SQLExpress"'
            DependsOn = "[Script]ExtractSQLEXPR"
        }
        
        Script AzureStorageEmulator
        {
          GetScript = {
            # Do Nothing
          }
          TestScript = {
            return !((Get-ScheduledTask -TaskName "Azure Storage Emulator" -ErrorAction SilentlyContinue) -eq $null)
          }
          SetScript = {
            Start-Process -FilePath "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\AzureStorageEmulator.exe" -Args "init -server localhost -forcecreate"
            schtasks.exe /create /xml "C:\software\Microsoft\Azure Storage Emulator.xml" /tn "Azure Storage Emulator" /ru "SYSTEM"
            shutdown -r -f -t 10
          }
          DependsOn = @("[Package]AzureStorageEmulator","[Package]SQLExpress","[File]AzureStorageEmulatorScheduledTask")
        }
        
        xRobocopy Hosts
        {
            Source = '\\privvmtcaape01.cloud.rockend.io\C$\Users\svcTeamCityAgent\.ssh'
            Destination = 'C:\Users\svcTeamCityAgent\.ssh'
            PsDscRunAsCredential = $robocopyCredential
        }
        
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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
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

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
        }

        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }
    }

    Node sqlServerEC
    {
        xDSCDomainjoin JoinDomain
        {
            Domain = $domainName
            Credential = $domainCredentials
            JoinOU = "OU=SQL,OU=allPrivate,OU=allServers,OU=allMachines,DC=cloud,DC=rockend,DC=io"
        }

        cChocoInstaller installChoco
        {
            InstallDir = "c:\software\choco"
        }

        cChocoPackageInstaller installChrome
        {
            Name        = "googlechrome"
            DependsOn   = "[cChocoInstaller]installChoco"
        }

        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'
        }

        Script OpenSqlPort
        {
            Credential = $sqlServerLocalAdminCredential
            GetScript = {
                # Do nothing
            }
            TestScript = {
                return !((Get-NetFirewallRule -Name 'Sql Server' -ErrorAction SilentlyContinue) -eq $null)
            }
            SetScript = {
                # Open SQL Server port inbound
                New-NetFirewallRule -DisplayName 'Sql Server' -Name 'Sql Server' -Protocol TCP -LocalPort 1433 -Direction Inbound -Action Allow -Profile Domain,Private
            }
        }

        Script SqlServerLogins
        {
            Credential = $sqlServerLocalAdminCredential
            GetScript = {
                # Do nothing
            }
            TestScript = {
                return !((sqlcmd -S . -d master -Q "SELECT 'Found' FROM sys.server_principals WHERE name = N'CLOUD\admin_product_EC'" | Select-String 'Found') -eq $null)
            }
            SetScript = {
                # Add admin group to sql server logins
                sqlcmd -S . -d master -Q "CREATE LOGIN [CLOUD\admin_product_EC] FROM WINDOWS WITH DEFAULT_DATABASE=[master]; ALTER SERVER ROLE [sysadmin] ADD MEMBER [CLOUD\admin_product_EC]"
            }
            DependsOn = "[xDSCDomainjoin]JoinDomain"
        }

        Script AddEcAdminsToRemoteDesktop
        {
            Credential = $sqlServerLocalAdminCredential
            GetScript = {
                # Do nothing
            }
            TestScript = {
                return !((net localgroup "Remote Desktop Users" | Select-String 'CLOUD\\admin_product_EC') -eq $null)
            }
            SetScript = {
                # Enable ec admin users remote desktop access
                net localgroup "Remote Desktop Users" /add "CLOUD\admin_product_EC"
            }
            DependsOn = "[xDSCDomainjoin]JoinDomain"
        }

        Script AddEcAdminsToLocalAdmin
        {
            Credential = $sqlServerLocalAdminCredential
            GetScript = {
                # Do nothing
            }
            TestScript = {
                return !((net localgroup "Administrators" | Select-String 'CLOUD\\admin_product_EC') -eq $null)
            }
            SetScript = {
                # Make ec admin users local admin
                net localgroup "Administrators" /add "CLOUD\admin_product_EC"
            }
            DependsOn = "[xDSCDomainjoin]JoinDomain"
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
