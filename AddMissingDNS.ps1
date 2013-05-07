if (Test-Path H:\servers-dns.txt)
{
$computers = Get-Content "H:\servers-dns.txt"
}
elseif (Test-Path H:\servers-backup.txt)
{
$computers = @()
$computers += "system,status"
$computers += Get-Content "H:\servers-backup.txt"
$computers | Set-Content "H:\servers-dns.txt"
}
else
{
Write-Host "Files don't exist."
}

$strComputers = Get-Content "h:\servers.txt"
foreach ($strComputer in $strComputers)
{
    $strComputer = $strComputer -replace " ","" #JIC there's a space in the name or at the end of the line
    Write-Host "Checking $strComputer..."
    $pingable = Test-Connection -Count 1 -ComputerName $($strComputer.ToUpper()) -Quiet
    if ($pingable)
    {
        Try
        {
            $nac = gwmi -ComputerName $strComputer win32_NetworkAdapterConfiguration | ? {$_.IPAddress}
            $ip = $nac.IPAddress.GetValue(0) #IPAddress is an array and the first one is the IPv4 address, some have a second IPv6 address
            Write-Host "$($strComputer.ToUpper())'s IP is: $ip"
            $ipSplit = $ip.Split(".")
            $CurrentPrimary = $nac.DNSServerSearchOrder.GetValue(0)
            $PrimaryShouldBe = "$($ipSplit.GetValue(0)).$($ipSplit.GetValue(1)).$($ipSplit.GetValue(2)).18"
            $NeedReplace = $CurrentPrimary -ne $PrimaryShouldBe
            if ($NeedReplace)
            {
                Write-Host "$($strComputer.ToUpper()) needs DNS set."
                $localDNS = @() #need to force the variable to be an array
                $localDNS = $localDNS + $PrimaryShouldBe
                $localDNS = $localDNS + $nac.DNSServerSearchOrder
                Write-Host "$($strComputer.ToUpper())'s DNS will be set to:"
                $localDNS
                $nac.SetDNSServerSearchOrder($localDNS) | out-null
                Remove-Variable localDNS
            }
            else
            {
                Write-Host "$($strComputer.ToUpper()) is good."
                $nac.DNSServerSearchOrder
            }
            Remove-Variable needreplace
            Remove-Variable ip 
            Remove-Variable ipSplit 
            Remove-Variable nac 
        }
        Catch
        {
            [system.exception]
            Write-Host "Error connecting to $($strComputer.ToUpper())"
            $Error
        }
    }
    else
    {
        Write-Host "$($strComputer.ToUpper()) seems to be down."
    }
    Remove-Variable strComputer 
}
