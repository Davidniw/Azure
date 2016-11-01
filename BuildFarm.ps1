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
    		DestinationPath = "C:\SQLInstall"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\Software\software\SQLJDBC"
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
