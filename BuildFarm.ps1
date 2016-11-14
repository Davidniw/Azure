configuration BuildFarm
{ 
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    $storageCredential = Get-AutomationPSCredential -Name 'storageCredential'

    Node Kondike
    {
        File Kondike
        {
            DestinationPath = "c:\inetpub\wwwroot"
    		Credential = $storageCredential
    		Ensure = "Present"
    		SourcePath = "\\prodrockcoresoftware.file.core.windows.net\software\Software\klondike\RElease\Klondike-Release-master"
    		Type = "Directory"
    		Recurse = $true
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
