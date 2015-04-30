# ------------------------------------------------------------------------
# NAME: tune-ssl-cipher-suites.ps1
# AUTHOR: Nathan Rice, naterice.com
# DATE: 2015/04/28
#
# KEYWORDS: letsencrypt
#
# COMMENTS: This file will set IIS to secure protocols/ciphers
#           Windows 2003+ machines. Requires a restart.
#
# TODO: Test with desktop versions of IIS
#
# REF: https://www.nartac.com/Products/IISCrypto/FAQ.aspx
#      https://www.nartac.com/blog/post/2013/04/19/IIS-Crypto-Explained.aspx
#      http://blogs.msdn.com/b/kaushal/archive/2011/10/02/support-for-ssl-tls-protocols-on-windows.aspx
#      https://msdn.microsoft.com/en-us/library/windows/desktop/ms724833(v=vs.85).aspx
#
# ------------------------------------------------------------------------

Function CheckWindowsVersion() {
	#Supported Ciphers/Protocols vary between versions.
	$OS = [Environment]::OSVersion
	If ($OS.Version.Major -ge 6 -and $OS.Version.Minor -ge 1) {
		#2008 R2+ 
		Return "2008R2";
	} ElseIf ($OS.Version.Major -ge 6 -and $OS.Version.Minor -eq 0) {
		Return "2008";
	} ElseIf ($OS.Version.Major -eq 5 -and $OS.Version.Minor -ge 1) {
		#2003/XP/2003R2
		Return "2003";
	} Else {
		Return "Incompatible";
	}
}

Function TuneSSLCiphers() {
	#This will fail if the user doesn't have rights,
	#possibly we should check for admin rights here.

	$WindowsVersion = CheckWindowsVersion
	
	#Disable insecure protocols
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\Multi-Protocol Unified Hello\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\PCT 1.0\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null

	#Enable TLS
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
	
	If ($WindowsVersion = "2008R2") {
		New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -Force | Out-Null
		New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
		New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
		New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'Enabled' -value 1 -PropertyType 'DWord' -Force | Out-Null
		New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -name 'DisabledByDefault' -value 0 -PropertyType 'DWord' -Force | Out-Null
	}

	$insecureCiphers = @(
	  'DES 56/56','NULL','RC2 128/128','RC2 40/128','RC2 56/128','RC4 40/128','RC4 56/128','RC4 64/128','RC4 128/128'
	)

	Foreach ($insecureCipher in $insecureCiphers) {
	  $key = (Get-Item HKLM:\).OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey($insecureCipher)
	  $key.SetValue('Enabled', 0, 'DWord')
	  $key.close()
	}
	 
	$secureCiphers = @(
	  'AES 256/256','AES 128/128','Triple DES 168/168'
	)
	Foreach ($secureCipher in $secureCiphers) {
	  $key = (Get-Item HKLM:\).OpenSubKey('SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers', $true).CreateSubKey($secureCipher)
	  New-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$secureCipher" -name 'Enabled' -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
	  $key.close()
	}
	 
	#Set hashes...
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\MD5' -name Enabled -value 0 -PropertyType 'DWord' -Force | Out-Null
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Hashes\SHA' -name Enabled -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
	 
	# Set KeyExchangeAlgorithms configuration...
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\Diffie-Hellman' -name Enabled -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
	New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\PKCS' -Force | Out-Null
	New-ItemProperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\KeyExchangeAlgorithms\PKCS' -name Enabled -value '0xffffffff' -PropertyType 'DWord' -Force | Out-Null
	
	If ($WindowsVersion = "2008" -or $WindowsVersion = "2008R2") {
		# Set secure order, mitigates BEAST, not supported in 2003...
		$cipherSuitesOrder = @(
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P521',
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P384',
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384_P256',
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P521',
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P384',
		  'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA_P256',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P521',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P521',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P384',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256_P256',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P384',
		  'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA_P256',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256_P256',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA_P256',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256_P256',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P521',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P384',
		  'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA_P256',
		  'TLS_DHE_DSS_WITH_AES_256_CBC_SHA256',
		  'TLS_DHE_DSS_WITH_AES_256_CBC_SHA',
		  'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256',
		  'TLS_DHE_DSS_WITH_AES_128_CBC_SHA',
		  'TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA',
		  'TLS_RSA_WITH_AES_256_CBC_SHA256',
		  'TLS_RSA_WITH_AES_256_CBC_SHA',
		  'TLS_RSA_WITH_AES_128_CBC_SHA256',
		  'TLS_RSA_WITH_AES_128_CBC_SHA',
		  'TLS_RSA_WITH_3DES_EDE_CBC_SHA'
		)
		$cipherSuitesAsString = [string]::join(',', $cipherSuitesOrder)
		New-ItemProperty -path 'HKLM:\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002' -name 'Functions' -value $cipherSuitesAsString -PropertyType 'String' -Force | Out-Null
	}
}

TuneSSLCiphers