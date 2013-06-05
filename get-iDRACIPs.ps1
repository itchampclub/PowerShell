<# you need to set these values as Administrator
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
#   $cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials"
    $cimSO = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -Encoding Utf8 -UseSsl
    $cimOptions = @{
    Authentication = "Basic"
    Credential = $using:cimCred
    Port = "443"
    SessionOption = $cimSO
    }
    $pingable = Test-Connection -Count 1 -ComputerName $using:Computer -Quiet
    if ($pingable)
    {
    $cimSession = New-CimSession @cimOptions -ComputerName $using:Computer
    $cimSoftwareIdentity = Get-CimInstance -CimSession $cimSession -ResourceUri "http://schemas.dell.com/wbem/wscim/1/cim-schema/2/DCIM_SoftwareIdentity"
    $cimSoftwareIdentity # | ? {$_.Status -eq "Installed"} | ft PSComputerName, ELementName, VersionString
    }
    else
    {
    Select-Object -InputObject $using:computer -Property @{name='PSComputerName';expression={$using:computer}}
    }
    }
}
}

workflow GetIdracIPs
{
param
(
[string[]]$VMHosts,
[string[]]$VIServer
)

$VMHosts = InlineScript
{
Add-PSSnapin vmware.vimautomation.core 
Connect-VIServer $using:VIServer | Out-Null
(Get-VMHost).name
}
foreach -parallel ($VMHost in $VMHosts){
inlinescript
{
Add-PSSnapin vmware.vimautomation.core 
Connect-VIServer $using:VIServer | Out-Null
function Get-VMHostWSManInstance {
param (
[Parameter(Mandatory=$TRUE,HelpMessage="VMHosts to probe")]
[VMware.VimAutomation.Client20.VMHostImpl[]]
$VMHost,

[Parameter(Mandatory=$TRUE,HelpMessage="Class Name")]
[string]
$class,

[switch]
$ignoreCertFailures,

[System.Management.Automation.PSCredential]
$credential=$null
)

$omcBase = "http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/"
$dmtfBase = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
$vmwareBase = "http://schemas.vmware.com/wbem/wscim/1/cim-schema/2/"

if ($ignoreCertFailures) {
$option = New-WSManSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
} else {
$option = New-WSManSessionOption
}
foreach ($H in $VMHost) {
if ($credential -eq $null) {
$hView = $H | Get-View -property Value
$ticket = $hView.AcquireCimServicesTicket()
$password = convertto-securestring $ticket.SessionId -asplaintext -force
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $ticket.SessionId, $password
}
$uri = "https`://" + $h.Name + "/wsman"
if ($class -cmatch "^CIM") {
$baseUrl = $dmtfBase
} elseif ($class -cmatch "^OMC") {
$baseUrl = $omcBase
} elseif ($class -cmatch "^VMware") {
$baseUrl = $vmwareBase
} else {
throw "Unrecognized class"
}
Get-WSManInstance -Authentication basic -ConnectionURI $uri -Credential $credential -Enumerate -Port 443 -UseSSL -SessionOption $option -ResourceURI "$baseUrl/$class"
}
}
$thisVMhost = Get-VMHost $using:VMhost
if ($thisVMhost.connectionstate -eq "Connected")
{
$iDRAC = Get-VMHostWSManInstance -VMHost $thisVMHost -class OMC_IPMIIPProtocolEndpoint -ignoreCertFailures
}

#Write-Output "$($thisVMhost.name),$($iDRAC.IPv4Address),$($iDRAC.MACAddress)"
Select-Object -InputObject $thisVMhost -Property name,connectionstate,@{name='iDRAC IP'; expression={$iDRAC.IPv4Address}},@{name='iDRAC MAC'; expression={$iDRAC.MACAddress}}
}
}
}

#$hourigvcs = GetIdracIPs -VIServer hourigvcs

#$cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials
