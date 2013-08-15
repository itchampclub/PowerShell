
$cred = Get-Credential
[void][System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement")

$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct)
$pc.ValidateCredentials($cred.UserName,$cred.GetNetworkCredential().Password)