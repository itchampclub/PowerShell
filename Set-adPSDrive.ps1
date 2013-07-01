$cred = Get-Credential -Message "Please enter AD Admin credentials."
ipmo ActiveDirectory
Remove-PSDrive ad
New-PSDrive -PSProvider activedirectory -Root "" -name AD -Credential $cred