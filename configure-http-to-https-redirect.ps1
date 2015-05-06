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
# TODO: Return 2008+ sites and SSL Binding status.
#       Return a list of IP's assigned to the machine.
#       Detect if SNI is installed.
#       Support IPv6?
#
# REF: http://www.jppinto.com/2009/01/automatically-redirect-http-requests-to-https-on-iis-6/
#
# ------------------------------------------------------------------------

#IIS 6 -- This doesn't seem to return the info I need, maybe relevant later
#$IISWMI = get-wmiobject -namespace "root/MicrosoftIISv2" -class IIsWebVirtualDirSetting
#$IISWMI | ft Name,Path,AppFriendlyName

Function Get-WebsiteObject() {
	#trying to mirror the 2008 object properties
	$objWebsite = New-Module -AsCustomObject -ScriptBlock {
    [string]$Name=$null
	[int]$ID=$null
	[string]$State=$null
	[string]$PhysicalPath=$null
	[string]$Bindings=$null

    Export-ModuleMember -Variable * -Function *}

	Return $objWebsite
}

Function GetIIS6Websites() {
	$IISWMIServerSetting = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IISWebServerSetting
	$IISWMIVirtualDirSetting = get-wmiobject -namespace "root/MicrosoftIISv2" -class IIsWebVirtualDirSetting
	
	$Sites = @()
	ForEach ($Site in $IISWMIServerSetting) {
		$SiteObj = Get-WebsiteObject

		$SSLBinding = @();
		ForEach ($tmpSecureBinding in $Site.SecureBindings) {
			$IP = $tmpSecureBinding.IP
			$Port = $tmpSecureBinding.Port -replace ":", ""
			$SSLBinding += "$IP`:$Port"
		};
		
		$SiteObj.ID = $Site.Name -replace "W3SVC/", ""
		$SiteObj.Name = $Site.ServerComment
		$SiteObj.Bindings = $SSLBinding
		$SiteObj.PhysicalPath = ($IISWMIVirtualDirSetting | Where-Object {$_.Name -like "W3SVC/" + $SiteObj.ID + "/root"}).Path
		
		
		$Sites += $SiteObj
	}
	
	Return $Sites
}




#Since there is no native way to redirect in IIS 6, I was thinking I could URL redirect
#HTTP requests to HTTPS based on the 403 error page that gets returned, via JavaScript.
#this method is obviously going to fail on browsers that do not have JavaScript enabled,
#maybe someone else can think of a better way.
#"<script>window.location = ""https:"" + window.location.href.substring(window.location.protocol.length)</script>"
