﻿<# you need to set these values as Administrator
Set-Item wsman:.\localhost\MaxBatchItems -Value 100
Set-Item wsman:.\localhost\Client\AllowUnencrypted -Value $true
Set-Item wsman:.\localhost\Client\TrustedHosts -Value *
Set-Item wsman:.\localhost\Client\Auth\Basic -Value true
#>

workflow GetFirmwareVersions
{
param
(
[string[]]$Computers,
[PSCredential]$cimCred
)
foreach -parallel ($Computer in $Computers){
inlinescript
    {
    #$cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials"
    $cimSO = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -Encoding Utf8 -UseSsl
    $cimOptions = @{
    Authentication = "Basic"
    Credential = $using:cimCred
    Port = "443"
    SessionOption = $cimSO
    }
    $cimSession = New-CimSession @cimOptions -ComputerName $using:Computer
    $cimSoftwareIdentity = Get-CimInstance -CimSession $cimSession -ResourceUri "http://schemas.dell.com/wbem/wscim/1/cim-schema/2/DCIM_SoftwareIdentity"
    $cimSoftwareIdentity # | ? {$_.Status -eq "Installed"} | ft PSComputerName, ELementName, VersionString
    }
}
}