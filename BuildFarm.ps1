configuration BuildFarm
{ 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName AzureRM.KeyVault
    
    #param for keyvault = svcSonarQubeDB

    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'
    $sonarQubeCredential = Get-AutomationPSCredential -Name 'svcSonarQubeDB'
    #$sonarQubeSecret = (Get-AzureKeyVaultSecret -VaultName prod-rock-core-keyVault -Name svcSonarQubeDB).SecretValueText
    #create credential hash table
    #$SonarQubePass = ConvertTo-SecureString $sonarQubeSecret -AsPlainText -Force
    #$SonarQubeCreds = New-Object System.Management.Automation.PSCredential (“svcSonarQubeDB@cloud.rockend.io”, $SonarQubePass)

    Node JumpBox
    {
        WindowsFeature RoleExample
        {
            Ensure  = "Present"
            Name    = "RDS-Gateway"
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
    	File SonarQube
    	{
    		DestinationPath = "C:\sonarqube-6.0\sonarqube-6.0"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\SonarQube\sonarqube-6.0\sonarqube-6.0"
    		Type = "Directory"
    		Recurse = $true
     	}
        
        #Run "c:\sonarqube-6.0\sonarqube-6.0\bin\windows-x86-64\InstallNTService.bat"
        #Machine needs to restart to refresh service
        
        Service SonarQube
        {
            Name        = "SonarQube"
            StartupType = "Automatic"
            Credential  = $sonarQubeCredential
            State       = "Running"
            DependsOn   = "[File]SonarQube"
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
}
