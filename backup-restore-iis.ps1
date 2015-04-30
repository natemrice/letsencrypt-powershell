# ------------------------------------------------------------------------
# NAME: backup-restore-iis.ps1
# AUTHOR: Nathan Rice, naterice.com
# DATE: 2015/04/28
#
# KEYWORDS: letsencrypt
#
# COMMENTS: The purpose of this file is to create a backup, list
#           successful backups, and restore available backups for all
#           supported versions of Windows. This is a work in progress and
#           should not be considered complete.
#
# ------------------------------------------------------------------------


Function CheckWindowsVersion() {
	#Backup methods changed from Windows 2003 to Windows 2008+
	#So using this to detect which version is in use.
	$OS = [Environment]::OSVersion
	If ($OS.Version.Major -ge 6) {
		#2008+ share backup methods
		return "2008";
	} ElseIf ($OS.Version.Major -eq 5 -and $OS.Version.Minor -ge 1) {
		#XP and 2003 share backup methods
		return "2003";
	} Else {
		return "Incompatible";
	}
}

Function CheckIISIsInstalled() {
	#Simple check to see if IIS is installed. Piping to >$null
	#to suppress output and it's PS 2.0+ compatible.
	Try {
		Get-Service W3SVC -ErrorAction Stop >$null 2>&1;
		return $True;
	} Catch {
		#$_.Exception.Message;
		return $False;
	}
}

##IisBack.zip
$Base64 = @"
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
AAAAAQABAF0AAAA3FQAAAAA=
"@
$IisBack = [System.Convert]::FromBase64String($Base64);

Function BackupIISConfig() {
	$WinDir = $env:windir;
	$TimeStamp = get-date -uFormat "%Y%m%d%H%M%S";
	
	#Sanity checks
	$WindowsVersion = CheckWindowsVersion
	If ($WindowsVersion -eq "Incompatible") {
		Write-Error [string]"This version of Windows is incompatible.";
		return $False;
	} ElseIf (!(CheckIISIsInstalled)) {
		Write-Error [string]"IIS was not detected.";
		return $False;
	}

	#If the Backup-WebConfiguration command exists we'll use that
	#as it's the preferred way.
	If (Get-Command Backup-WebConfiguration -CommandType Cmdlet -errorAction SilentlyContinue) {
		Try {
			Backup-WebConfiguration -Name "letsencrypt-$TimeStamp" -ErrorAction Stop;
		} Catch {
			Write-Error $_.Exception.Message;
			return $False;
		}

		If (!(Test-Path "$WinDir\System32\inetsrv\backup\letsencrypt-$TimeStamp")) {
			Write-Error "Backup directory does not exist. IIS backup seems to have failed.";
			return $False;
		} Else {
			#Backup success!
			return $True;
		}
	} ElseIf ($WindowsVersion = "2003") {
	#If the Backup-WebConfiguration command doesn't exist, we'll
	#use iisback.vbs. If it doesn't exist, we'll create it from
	#the embedded base64.
		If (!(Test-Path "$WinDir\System32\iisback.vbs")) {
			#If iisback.vbs doesn't exist, create it.
			Try {
				Set-Content -Path "iisback.zip" -Value $IisBack -Encoding Byte;
				$Shell = New-Object -Com Shell.Application;
				$ZipFile = $Shell.NameSpace((Get-Location).Path + "\iisback.zip");
				$Shell.NameSpace((Get-Location).Path).CopyHere($ZipFile.Items());
				Remove-Item iisback.zip;
				$IisBackPath = (Get-Location).Path + "\iisback.vbs";
			} Catch {
				Write-Error "Failed to find IisBack.vbs and failed to create it.";
				return $False;
			}
		} Else {
			$IisBackPath = "$WinDir\System32\iisback.vbs";
		}
		
		$Backup = "$WinDir\System32\cscript.exe $IisBackPath /backup /b letsencrypt$TimeStamp";
		#Write-Host $Backup;
		iex $Backup;
		
		
		#TODO: Verify backups was successful.
	} Else {
		Write-Error "Something unexpected went wrong!";
		return $False;
	}
}

BackupIISConfig;
