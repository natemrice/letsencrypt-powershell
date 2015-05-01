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

#IIS 6
$IISWMI = get-wmiobject -namespace "root/MicrosoftIISv2" -class IIsWebVirtualDirSetting

$IISWMI | ft Name,Path,AppFriendlyName

"<script>window.location = ""https:"" + window.location.href.substring(window.location.protocol.length)</script>"