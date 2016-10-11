configuration BuildFarm
{ 
param( 
    [Parameter(Mandatory=$true)] 
    [ValidateNotNullorEmpty()] 
    [PSCredential] $storageCredential.GetNetworkCredential().Password
    )
    

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
		Ensure = "Preset"
		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\SQLJDBC"
		Type = "Directory"
		Recurse = $true
 	}

        WindowsFeature IIS
        {
            Ensure               = 'Absent'
            Name                 = 'Web-Server'

        }
    }
}