[CmdletBinding(SupportsShouldProcess=$true)]
Param()

$users = Get-ADUser -Filter * -Properties proxyaddresses
$maxProxy = $users | %{([array]$_.proxyaddresses).GetUpperBound(0)} | Sort | Select -Last 1
foreach ($u in $users)
{
$proxyaddress = [ordered]@{}
$proxyaddress.Add("User",$u.name)
for ($i=0; $i -le $maxProxy; $i++)
{
$proxyaddress.add("proxyaddress_$i",$u.proxyaddresses[$I])
} #end for
[pscustomobject]$proxyAddress | Export-Csv -Path h:\fso\proxyaddresses.csv -NoTypeInformation –Append -Force
Write-Verbose $proxyaddress | Select * #just to see if it made it this far.
Remove-Variable -Name proxyAddress
}
