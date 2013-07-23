ipmo activedirectory
$RigPersonnelOUs = gci "AD:\OU=Personnel,OU=Rigs,OU=All Users,DC=NOBLE,DC=CC" | ? objectclass -eq organizationalunit
foreach ($OU in $RigPersonnelOUs)
{
$CountOfUsersInOU = (gci ad:\$($OU.distinguishedName) | ? objectclass -eq user).count
Write-Host """$($OU.Name)"" OU has $CountOfUsersInOU users."
$hs=@{}
Get-ADUser -SearchBase $OU.distinguishedName -Filter * -Properties memberof | select -ExpandProperty memberof | %{$hs[$_]++}
$hs.GetEnumerator() | sort Value -Descending | ? Value -gt $($CountOfUsersInOU*0.75)| ft -AutoSize #Gets groups represented in over 75% of users.
}