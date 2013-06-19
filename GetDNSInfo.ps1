workflow GetDNSInfo
{
param
(
[string[]]$Computers
)
foreach -parallel ($Computer in $Computers)
{
$wmiResult = gwmi -psComputerName $Computer -class win32_NetworkAdapterConfiguration
}
inlinescript
    {

    $nac = $using:wmiResult | ? {$_.IPAddress}
    $DNSEntries = $nac.DNSServerSearchOrder.split(" ")
    $IPs = @()
    $IPs = $IPs + $nac.IPAddress.split(" ")
    $strComputer = $using:Computer
    $IP = $IPs.GetValue(0)
    Write-Output "--------------------------------------------"
    Write-Output "$strComputer's IP is: $ip"
    $ipSplit = $ip.Split(".")
    $CurrentPrimary = $DNSEntries.GetValue(0)
    $PrimaryShouldBe = "$($ipSplit.GetValue(0)).$($ipSplit.GetValue(1)).$($ipSplit.GetValue(2)).18"
    $NeedReplace = $CurrentPrimary -ne $PrimaryShouldBe
    if ($NeedReplace)
    {
    Write-Output "$strComputer needs DNS set."
    $localDNS = @() #need to force the variable to be an array
    $localDNS = $localDNS + $PrimaryShouldBe
    $localDNS = $localDNS + $DNSEntries
    Write-Output "$strComputer's DNS needs to be set to:"
    $localDNS
    #$nac.SetDNSServerSearchOrder($localDNS) | out-null
    Remove-Variable localDNS
    }
    else
    {
    Write-Output "$strComputer is good."
    $DNSEntries
    }
    Remove-Variable needreplace
    Remove-Variable ip 
    Remove-Variable ipSplit 
    Remove-Variable nac 
    }

}