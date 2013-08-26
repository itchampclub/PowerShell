if(!((gmo).Name.ToLower().Contains('activedirectory'))){Write-Error "Active Directory module needs to be loaded.";return}
if(!((Get-PSSession).ConfigurationName.ToLower().Contains('microsoft.exchange'))){Write-Error "Need to establish an implicit remoting session to exchange CAS.";return}

$MyDir = $(Split-Path $((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path)

if(
!$((Get-PSDrive mydir -ea Ignore).root -eq $MyDir)
){
Remove-PSDrive MyDir -ErrorAction Ignore
New-PSDrive -Root $MyDir -Name MyDir -PSProvider FileSystem
}

$userlist = gc MyDir:\UserList.txt
foreach($user in $userlist){Get-ADUser $user}