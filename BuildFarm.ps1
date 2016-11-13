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

Invoke-Command -ScriptBlock {C:\sonarqube-6.0\bin\windows-x86-64\InstallNTService.bat}
