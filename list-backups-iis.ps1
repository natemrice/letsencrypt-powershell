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

Function ListBackups(){
	#Work in progress, going to return an array of backups
	$objBackups = @()
	$objBackup = New-Module -AsCustomObject -ScriptBlock {
    [string]$Name=$null
	[System.Nullable``1[[System.DateTime]]]$Date=$null
    Function Age {
        Write-Output ($Date-(Get-Date)).ToString()
    }
    Export-ModuleMember -Variable * -Function *}

	If (Get-Command Get-WebConfigurationBackup -CommandType Cmdlet -errorAction SilentlyContinue) {
	#2008+ Backups
		$BackupIndex = 0;
		ForEach ($Backup In Get-WebConfigurationBackup) {
			$BackupName = $Backup.Name;
			$BackupDate = $Backup.CreationDate;
			If ($BackupName -like "letsencrypt*"){
				Write-Host "$BackupIndex.) $BackupName - $BackupDate" -foregroundcolor green;
			} Else {
				Write-Host "$BackupIndex.) $BackupName - $BackupDate";
			}
			$BackupIndex++;
		}
		
		Return $True;
	
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
				
				If ($BackupLocation -like "letsencrypt*"){
					Write-Host "$BackupIndex.) $BackupLocation - $BackupDate" -foregroundcolor green;
				} Else {
					Write-Host "$BackupIndex.) $BackupLocation - $BackupDate";
				}
				$BackupIndex++;
			} Catch {
				Exit;
			}
		}
		
		Return $True;
	}
}

ListBackups