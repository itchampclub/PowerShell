$startDir = (gl).Path
cd 'AD:\DC=NOBLE,DC=CC'
cd '.\OU=All Users'
cd .\OU=Terminations
$termOU = (gl).Path
$count = 30
$seedDir = "\\houhomes\users$\TBecker\GitHub\PowerShell"
$seedPST = "\\houmailbk\terminations`$\test.pst"
$AccountPassword = ConvertTo-SecureString -String "P@ssword1234" -AsPlainText -Force

for ($i = 1; $i -le $count; $i++)
{
    $newuser = New-Object Microsoft.ActiveDirectory.Management.ADUser
    $newuser.DisplayName = "Term User $i"
    $newuser.SamAccountName = "termuser$i"
    $newuser.GivenName = "Termination"
    $newuser.Surname = "User $i"
    $newuser.EmployeeID = "dummy$i$i"
    $newuser.Enabled = $true
    $newuser.UserPrincipalName = "$($newuser.SamAccountName)@noblecorp.com"

    $HomeDirectory = "\\houhomes\users$\termuser$i"
    sl $termOU
    New-ADUser -Instance $newuser -Name $newuser.SamAccountName -AccountPassword $AccountPassword
    do
    {
    sleep -Seconds 5
    $thisuser = try{Get-ADUser $newuser.SamAccountName}catch{}
    }
    until($thisuser -ne $null)
    sl $startDir

    Set-ADUser $thisuser -HomeDirectory $HomeDirectory -HomeDrive "H:"
    New-Item -Path $HomeDirectory -ItemType directory -Force |Out-Null
    sleep -Seconds 10
    $HomeDirectoryACL = Get-Acl $HomeDirectory
    $AccessRule=NEW-OBJECT System.Security.AccessControl.FileSystemAccessRule ("NOBLE\$($thisuser.SamAccountName)",”FullControl”,”ContainerInherit, ObjectInherit”,”None”,”Allow”)
    $HomeDirectoryACL.AddAccessRule($AccessRule)

    Set-Acl -Path $HomeDirectory -AclObject $HomeDirectoryACL

    Copy-Item -Path $seedDir -Destination $HomeDirectory -Recurse #-WhatIf

    Enable-ExCAS_Mailbox -Identity $thisuser.SamAccountName -Alias $thisuser.SamAccountName -Database hou-maildb8 #-WhatIf
    sleep -Seconds 30
    New-ExCAS_MailboxImportRequest -FilePath $seedPST -Mailbox $thisuser.SamAccountName
    Remove-Variable newuser,thisuser,homedirectory,accessrule,homedirectoryacl -ea Ignore
}

sl $startDir
Remove-Variable startdir,currentdir,termou -ea Ignore