# ------------------------------------------------------------------------
# NAME: backup-restore-iis.ps1
# AUTHOR: Nathan Rice, naterice.com
# DATE: 2015/04/28
#
# KEYWORDS: letsencrypt
#
# COMMENTS: This file will list backups for IIS on Windows 2003+ machines.
#
# TODO: 
#
# ------------------------------------------------------------------------

Function Get-BackupObject() {
	$objBackup = New-Module -AsCustomObject -ScriptBlock {
    [string]$Name=$null
	[System.Nullable``1[[System.DateTime]]]$Date=$null
    Function Age {
        Write-Output ($Date-(Get-Date)).ToString()
    }
    Export-ModuleMember -Variable * -Function *}

	Return $objBackup
}

Function ListBackups(){
	$objBackups = @()

	If (Get-Command Get-WebConfigurationBackup -CommandType Cmdlet -errorAction SilentlyContinue) {
	#2008+ Backups
		ForEach ($Backup In Get-WebConfigurationBackup) {
			$objBackup = Get-BackupObject
			$objBackup.Name = $Backup.Name;
			$objBackup.Date = [datetime]$Backup.CreationDate;
			
			$objBackups += $objBackup;
		}
		
		Return $objBackups;
	} Else {
	#2003 Backups
		Try {
			$IISComputer = Get-WmiObject -Namespace "root/MicrosoftIISv2" -Class "IISComputer";
		} Catch {
			Write-Error "There was an error initializing the IIS WMI object.";
			return $False;
		}
			
		$BackupIndex = 0;
		While ($True) {
			Try {
				$BackupObj = $IISComputer.EnumBackups("",$BackupIndex);
				$BackupLocation = $BackupObj.BackupLocation;
				$BackupDate = $BackupObj.BackupDateTimeOut;

				$objBackup = Get-BackupObject
				$objBackup.Name = $BackupLocation;
				$objBackup.Date = [datetime]$BackupDate;

				$objBackups += $objBackup;
				
				$BackupIndex++;
			} Catch {
				Exit;
			}
		}
		
		Return $objBackups;
	}
}

ListBackups