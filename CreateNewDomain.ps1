<#
    .Parameter domainName
    The domain name for your On-Premises domain as determined by the O365 Demo set-up
#>
configuration CreateNewDomain             
{             
    param             
    (             
		[Parameter(Mandatory)]
        [System.string]$domainName  
    )   
	
    Import-DSCResource -ModuleName xStorage        
    Import-DscResource -ModuleName xActiveDirectory 
	Import-DscResource –ModuleName xPSDesiredStateConfiguration	
     
	    $safemodeAdministratorCred = Get-AutomationPSCredential -Name 'ONPREMISEADMIN'
		$domainCred  = Get-AutomationPSCredential -Name 'ONPREMISEDOMAINADMIN'
		            
	 
    Node DomainController             
    {             
        xWaitforDisk Disk2
        {
             DiskId = 2
             RetryIntervalSec = 60
             RetryCount = 60
        }

        xDisk EVolume
        {
             DiskId = 2
             DriveLetter = 'E'
             Size = 9970MB
             FSFormat = 'NTFS'
             FSLabel = 'SYSVOL'
             DependsOn = '[xWaitForDisk]Disk2'
        }

        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
            
        File ADFiles            
        {            
            DestinationPath = 'E:\NTDS'            
            Type = 'Directory'            
            Ensure = 'Present'
            DependsOn = '[xWaitForDisk]Disk2'          
        }            
                    
        WindowsFeature ADDSInstall             
        {             
            Ensure = "Present"             
            Name = "AD-Domain-Services"             
        }            
            
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }            
            
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {        

            DomainName = $domainName             
            DomainAdministratorCredential = $domainCred             
            SafemodeAdministratorPassword = $safemodeAdministratorCred            
            DatabasePath = 'E:\NTDS'            
            LogPath = 'E:\NTDS'            
            DependsOn = "[WindowsFeature]ADDSInstall","[File]ADFiles"            
        }            
            
    }             
}            
            
# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "ONPREMDC01"             
            Role = "Primary DC"                         
            RetryCount = 20              
            RetryIntervalSec = 30            
            PsDscAllowPlainTextPassword = $true            
        }            
    )             
}             

  