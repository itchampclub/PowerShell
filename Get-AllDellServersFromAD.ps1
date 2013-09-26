#requires -module activedirectory
#requires -version 3

Get-Job|Remove-Job -Force

$Systems = (Get-ADComputer -Filter {operatingsystem -like "*server*"} -Properties name).name

#region Ping Servers from AD
$Systems | foreach{Test-Connection -AsJob -cn $_ -Count 1 | Out-Null}
Remove-Variable i -ea Ignore
do
{
$i+=1
Write-Progress -Status "Waiting for $i seconds... Number of jobs running: $((Get-Job -state Running).count)" -Activity "Pinging Servers" -PercentComplete $((($(get-job).count-(Get-Job -State Running).count)/$(get-job).count)*100)
sleep -Seconds 1
}
until(((get-job -State Running).count -eq 0) -or $i -ge 15)

Write-Progress -Status "Stopping $((Get-job -State Running).count) PSjobs." -Activity "Cleaning up Ping jobs."
Get-Job -State Running | Stop-Job

$PingResults = Get-Job | Receive-Job -Wait
Get-Job | Remove-Job
$PingSuccess = $PingResults | ? statuscode -eq 0 | select address
#endregion 
#region Get Servers that have Dell WMI namespaces from pingable servers
($PingResults|? statuscode -eq 0).IPV4Address.IPAddressToString|foreach{gwmi -Namespace "root\cimv2" -Class "__Namespace" -cn $_ -ErrorAction Ignore -AsJob | Out-Null}                             

Remove-Variable i -ea Ignore
do
{
$i++
Write-Progress -Status "Waiting for $i seconds... Number of jobs running: $((Get-Job -state Running).count)" -Activity "Finding Dell namespaces on Servers" -PercentComplete $((($(get-job).count-(Get-Job -State Running).count)/$(get-job).count)*100)
sleep -Seconds 1
}
until(((get-job -State Running).count -eq 0) -or $i -ge 90)
Write-Progress -Status "Stopping $((Get-job -State Running).count) PSjobs." -Activity "Cleaning up namespace jobs."
Get-Job -State Running | Stop-Job

$NamespaceResults = Get-Job | Receive-Job

Get-Job | Remove-Job

$HasDellNamespace = ($NamespaceResults | ? name -eq "Dell").PSComputerName
#endregion
#region Get iDRAC IPs from Servers that have Dell WMI namespaces
$HasDellNamespace | foreach{gwmi -AsJob -Namespace root\cimv2\dell -Class Dell_RemoteAccessServicePort -cn $_ -Property accessinfo,systemname -ErrorAction Ignore |Out-Null}                          

Remove-Variable i -ea Ignore
do
{
$i++
Write-Progress -Status "Waiting for $i seconds... Number of jobs running: $((Get-Job -state Running).count)" -Activity "Finding iDRAC IPs" -PercentComplete $((($(get-job).count-(Get-Job -State Running).count)/$(get-job).count)*100)
sleep -Seconds 1
}
until(((get-job -State Running).count -eq 0) -or $i -ge 90)
Write-Progress -Status "Stopping $((Get-job -State Running).count) PSjobs." -Activity "Cleaning up iDRAC jobs."
Get-Job -State Running | Stop-Job

$iDracResults = Get-Job | Receive-Job

Get-Job | Remove-Job
#endregion

$iDracResults