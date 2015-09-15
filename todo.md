###TODO:
 - Figuring out how to support various client security enhancements like
	1. ~~tuning cipher suites~~
	2. enabling HTTP -> HTTPS redirection -> WIP: configure-http-to-https-redirect.ps1
	3. ~~enabling OCSP pinning~~
		On by default in IIS 7+ according to this, (IIS 6 Unsupported):
		https://technet.microsoft.com/en-us/library/hh826044%28v=ws.10%29.aspx
		
	4. setting HTTP headers (either universal or user-agent dependent)

 - ~~Figuring out how to support "rollback" of IIS configuration changes.~~
 
 [~~Metabase Backup in 03~~](https://support.microsoft.com/en-us/kb/324277)
 
 [~~Restoring IIS Configurations Using Iisback.vbs~~](https://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/7429a26d-45f0-41fe-bf45-a6e1d3be7ce1.mspx?mfr=true)
 
 [~~Listing IIS Backup Configurations Using Iisback.vbs~~](https://www.microsoft.com/technet/prodtechnol/WindowsServer2003/Library/IIS/05001ec3-be42-431a-bfe8-08c865564037.mspx?mfr=true)
 
