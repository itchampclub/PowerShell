$computers = Get-Content H:\servers-backup.txt
if (test-path "h:\idracs.txt")
{Remove-Item "h:\idracs.txt"}
foreach ($computer in $computers)
{
$ip = [System.Net.Dns]::GetHostAddresses($computer)
$ipOctets = $ip.IPAddressToString.Split(".")
"$($ipOctets.GetValue(0)).$($ipOctets.GetValue(1)).$($ipOctets.GetValue(2)).15" | Out-File -Append -FilePath H:\idracs.txt
}