function Parse-RACGetOutput ($RACOutput) {
	$object = New-Object system.Object
	foreach ($line in $RACoutput) {
		if ($line.trim().contains("=") -gt 0) {
			$line = $line.Trim("# ")
			$result = $line.Split("=")
			#$object = New-Object system.Object
			$object | add-member -MemberType NoteProperty -Name $result[0] -value $result[1]
			#$arrayobj += $object
			}
		}
	return $object
	}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"

$Error.Clear()
$newpassword = "CountDracula"
$racadmpath = "C:\Program Files\Dell\SysMgt\rac5"
New-PSDrive -Name scripts -PSProvider FileSystem -Root '\\houhomes\users$\tbecker\GitHub\PowerShell' -ErrorAction Ignore
Set-Location scripts:\
$unknown = gc .\noble\test.csv | ConvertFrom-Csv
$creds = Get-Credential
$unknown."device name" |
foreach {
if(
(Parse-RACGetOutput($(racadm -r $_ -u $creds.UserName -p $creds.GetNetworkCredential().password getconfig -g cfgUserAdmin -i 1))).cfgUserAdminUserName -eq 'root'
){
"Changing Password on $_ at index 1."
racadm -r $_ -u $creds.UserName -p $creds.GetNetworkCredential().password config -g cfgUserAdmin -o cfgUserAdminPassword -i 1 $newpassword
}else{
if($Error.Count -gt 0){$Error.exception.message.replace("R:","R on ${_}:");$Error.Clear();return}
if(
(Parse-RACGetOutput($(racadm -r $_ -u $creds.UserName -p $creds.GetNetworkCredential().password getconfig -g cfgUserAdmin -i 2))).cfgUserAdminUserName -eq 'root'
){
"Changing Password on $_ at index 2."
racadm -r $_ -u $creds.UserName -p $creds.GetNetworkCredential().password config -g cfgUserAdmin -o cfgUserAdminPassword -i 2 $newpassword
}
}
}
$Error.Clear()
$ErrorActionPreference = $oldErrorActionPreference