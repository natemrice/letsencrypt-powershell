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
# TODO: Everything.
#
# REF: http://www.jppinto.com/2009/01/automatically-redirect-http-requests-to-https-on-iis-6/
#
# ------------------------------------------------------------------------

#IIS 6 -- This doesn't seem to return the info I need, maybe relevant later
#$IISWMI = get-wmiobject -namespace "root/MicrosoftIISv2" -class IIsWebVirtualDirSetting
#$IISWMI | ft Name,Path,AppFriendlyName

#This does seem to return SSL Bindings but I haven't figured out the
#logic behind the bindings that seems appropriate
$IISWMI = get-wmiobject -namespace "root/MicrosoftIISv2" -Class IISWebServerSetting
$IISWMI | ft ServerComment,

ForEach ($Site in $IISWMI) {
	$SSLBinding = @(); 
    foreach ($tmpSecureBinding in $_.SecureBindings) {
        $SSLBinding += $tmpSecureBinding.Port 
    };
	$SSLBinding; 
}

#Since there is no native way to redirect in IIS 6, I was thinking I could URL redirect
#HTTP requests to HTTPS based on the 403 error page that gets returned, via JavaScript.
#this method is obviously going to fail on browsers that do not have JavaScript enabled,
#maybe someone else can think of a better way.
#"<script>window.location = ""https:"" + window.location.href.substring(window.location.protocol.length)</script>"
