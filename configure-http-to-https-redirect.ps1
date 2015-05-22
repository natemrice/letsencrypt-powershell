# ------------------------------------------------------------------------
# NAME: configure-http-to-https-redirect.ps1
# AUTHOR: Nathan Rice, naterice.com
# DATE: 2015/04/30
#
# KEYWORDS: letsencrypt
#
# COMMENTS: This file will force http to https redirection for Windows
#           2003+ IIS
#           
#  
# TODO: Configure HttpError property per site
#       Detect if SNI is installed.
#       Support IPv6?
#       Error handling
#
# REF: http://www.jppinto.com/2009/01/automatically-redirect-http-requests-to-https-on-iis-6/
#
# ------------------------------------------------------------------------

$4034Page = "403-4.htm";

Function CheckIISIsInstalled() {
	# Simple check to see if IIS is installed. Piping to >$null
	# to suppress output and it's PS 2.0+ compatible.
	Try {
		Get-Service W3SVC -ErrorAction Stop >$null 2>&1;
		Return $True;
	} Catch {
		#$_.Exception.Message;
		Return $False;
	}
}

Function CheckWindowsVersion() {
	# Backup methods changed from Windows 2003 to Windows 2008+
	# So using this to detect which version is in use.
	$OS = [Environment]::OSVersion
	If ($OS.Version.Major -ge 6) {
		# 2008+ share backup methods
		Return "2008";
	} ElseIf ($OS.Version.Major -eq 5 -and $OS.Version.Minor -ge 1) {
		# XP and 2003 share backup methods
		Return "2003";
	} Else {
		Return "Incompatible";
	}
}

Function CheckWebScriptingTools(){
	# If this is Windows 2008+ and IIS is installed, we need
	# scripting tools to manipulate it.
	
	If (CheckWindowsVersion = "2008") {
		Import-Module servermanager;
		If (CheckIISIsInstalled) {
			If ((Get-WindowsFeature Web-Scripting-Tools).Installed) {
				Return $True;
			} Else {
				Add-WindowsFeature Web-Scripting-Tools;
			}
		}
	}
}


# ServerState codes
Function Get-State($State){
	Switch($State){
		1 {Return "Starting"}
		2 {Return "Started"}
		3 {Return "Stopping"}
		4 {Return "Stopped"}
		5 {Return "Pausing"}
		6 {Return "Paused"}
		7 {Return "Continuing"}
		default {"Error"}
	}
}

Function Get-WebsiteObject() {
	# trying to mirror the 2008 object properties
	$objWebsite = New-Module -AsCustomObject -ScriptBlock {
	[string]$Name=$null;
	[int]$ID=$null;
	[string]$State=$null;
	[string]$PhysicalPath=$null;
	[object]$Bindings=$null;

	Export-ModuleMember -Variable * -Function *}

	Return $objWebsite;
}

Function Get-BindingObject() {
	# Returns a binding object
	$objBinding = New-Module -AsCustomObject -ScriptBlock {
	[string]$Name=$null;
	[string]$IP=$null;
	[int]$Port=$null;
	[string]$Type=$null;

	Export-ModuleMember -Variable * -Function *}

	Return $objBinding;
}

Function GetIIS6Websites() {
	# Sanity checks
	$WindowsVersion = CheckWindowsVersion
	If ($WindowsVersion -eq "Incompatible") {
		Write-Error "This version of Windows is incompatible.";
		Return $False;
	} ElseIf (!(CheckIISIsInstalled)) {
		Write-Error "IIS was not detected.";
		Return $False;
	}
	CheckWebScriptingTools

	$IISWMIServerSetting = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IISWebServerSetting;
	$IISWMIVirtualDirSetting = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IIsWebVirtualDirSetting;
	$IISWMIWebServer = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IIsWebServer;
	
	$Sites = @()
	ForEach ($Site In $IISWMIServerSetting) {
		$SiteObj = Get-WebsiteObject;

		$Bindings = @();
	
		# Secure Bindings
		ForEach ($SecureBinding In $Site.SecureBindings) {
			If ($SecureBinding.Port.Length -gt 0) {
				$NewBinding = Get-BindingObject;
			
				$NewBinding.IP = $SecureBinding.IP;
				$NewBinding.Port = $SecureBinding.Port -replace ":", "";
				$NewBinding.Type = "https";
				
				$Bindings += $NewBinding;
			}
		};
		
		# Normal Bindings
		ForEach ($Binding In $Site.ServerBindings) {
			If ($SecureBinding.Port.Length -gt 0) {
				$NewBinding = Get-BindingObject;
			
				$NewBinding.Name = $Binding.Hostname;
				$NewBinding.IP = $Binding.IP;
				$NewBinding.Port = $Binding.Port;
				$NewBinding.Type = "http";
				
				$Bindings += $NewBinding;
			}
		};
		
		
		$SiteObj.ID = $Site.Name -replace "W3SVC/", "";
		$SiteObj.Name = $Site.ServerComment;
		$SiteObj.Bindings = $Bindings;
		$SiteObj.PhysicalPath = ($IISWMIVirtualDirSetting | Where-Object {$_.Name -like "W3SVC/" + $SiteObj.ID + "/root"}).Path;
		$SiteObj.State = Get-State ($IISWMIWebServer | Where-Object {$_.Name -like "W3SVC/" + $SiteObj.ID}).ServerState;
		
		$Sites += $SiteObj;
	}
	
	Return $Sites;
}

Function GetActiveIPs(){
	# We need a list of IP's assigned to this machine so we
	# know if they are available to bind SSL to.
	$ActiveIPs = @();
	$Nics = (get-WmiObject Win32_NetworkAdapterConfiguration) | Where-Object {$_.IPAddress.Length -gt 0}
	ForEach ($ActiveNic In $Nics) {
		ForEach ($IP In $ActiveNic.IPAddress) {
			$ActiveIPs += $IP;
		}
	}
	
	Return $ActiveIPs;
}

Function SetRequireSSL($SiteID) {
	Set-WMIInstance -Path "\\localhost\root\MicrosoftIISv2:IIsWebVirtualDirSetting='W3SVC`/$SiteID`/root'" -argument @{AccessSSLFlags="264"} | Out-Null;
}

Function ConfigureSSLRedirect($SiteID) {
	# Since there is no native way to redirect in IIS 6, I was thinking I could URL redirect
	# HTTP requests to HTTPS based on the 403 error page that gets returned, via JavaScript.
	# this method is obviously going to fail on browsers that do not have JavaScript enabled,
	# maybe someone else can think of a better way.
	
	# ToDo: Need to read/write HttpErrors and disable HTTPS requirement on redirect page.
	$RedirectPage = "<script>window.location = 'https:' + window.location.href.substring(window.location.protocol.length)</script>"
	
	If (Get-Command Get-Website -CommandType Cmdlet -errorAction SilentlyContinue) {
		$WebSites = Get-Website;
	} Else {
		$WebSites = GetIIS6Websites;
	}
	
	If ($WebSites.Count -eq 0) { 
		Write-Error "IIS interrogation Returned 0 websites.";
		Exit;
	}
	
	# Compatibility with the IIS6 custom object...
	$JustSiteIds = @();	ForEach ($WebSite In $WebSites) { $JustSiteIds += $WebSite.ID }
	
	If ($JustSiteIds -NotContains $SiteID)  { 
		Write-Error "Website ID not found after interrogating IIS.";
		Exit;
	}
	
	ForEach ($WebSite In $WebSites) {
		If ($WebSite.ID -eq $SiteID) {
			If (!(Test-Path "$WebSite.PhysicalPath`\$4034Page")) {
				# If the redirect page doesn't exist, create it.
				Try {
					$RedirectPage | Out-File "$WebSite.PhysicalPath`\$4034Page";
				} Catch {
					Write-Error "Failed to create 403.4 redirect page at path: $WebSite.PhysicalPath`\$4034Page";
				}
			}
		}
	}
	
	# This doesn't work yet...
	# Now we will cycle through each site and set the 403.4
	# page to use the custom 403.4 redirect page.
	$IISWMIVirtualDirSetting = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IIsWebVirtualDirSetting
	ForEach ($Site In $IISWMIVirtualDirSetting) {
		$HttpErrorCode = $Site.HttpErrorCode;
		$HttpErrorSubCode = $Site.HttpErrorSubCode;
		$HttpErrors = $Site.HttpErrors;
		$SitePath = $Site.Path;
		
		ForEach ($HttpError In $HttpErrors) {
			If (($HttpError).HttpErrorCode -eq "403" -and ($HttpError).HttpErrorSubCode -eq "4") {
				Write-Output $HttpError;
				
				($HttpError).HandlerLocation = "$SitePath`\$4034Page";
			}
		}
	}
	
	
}

#MultiString Array
#[string[]]$NewHttpErrors = @()

#SetRequireSSL 87257621





