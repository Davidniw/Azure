configuration BuildFarm
{ 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'

    Node TeamCity
    {
        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'

        }
    }

    Node SonarQube
    {
    	File SQLBinaryDownload
    	{
    		DestinationPath = "C:\sonarqube-6.0"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\SonarQube\sonarqube-6.0\sonarqube-6.0"
    		Type = "Directory"
    		Recurse = $true
     	}
        
        Package PackageExample
        {
            Ensure      = "Present"
            Path        = "c:\sonarqube-6.0\bin\windows-x86-64\InstallNTService.bat"
            Name        = "sonarqube"
            ProductId   = "ACDDCDAF-80C6-41E6-A1B9-8ABD8A05027E"
            DependsOn   = "[File]SQLBinaryDownload"
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
