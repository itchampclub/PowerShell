ipmo activedirectory
$RigPersonnelOUs = gci "AD:\OU=Personnel,OU=Rigs,OU=All Users,DC=NOBLE,DC=CC" | ? objectclass -eq organizationalunit
foreach 
(
$OU in $RigPersonnelOUs
)
{
$CountOfUsersInOU = (gci ad:\$($OU.distinguishedName) | ? objectclass -eq user).count

Write-Host """$($OU.Name)"" OU has $CountOfUsersInOU users."

$ht=@{}

Get-ADUser -SearchBase $OU.distinguishedName -Filter * -Properties title |
    ? title -ne $null |
        select -ExpandProperty title |
            %{$ht[$_]++}

$ht.GetEnumerator() |
    sort Value -Descending |
        ft -AutoSize
}