configuration BuildFarm
{ 
    
    $storageCredential = Get-AutomationPSCredential -Name 'domainCreds'

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
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\SQLJDBC"
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
