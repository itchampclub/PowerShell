ipmo ActiveDirectory

function Set-ADGroupMembershipFromExpectedList
{
param
(
[Parameter(Position=0, Mandatory=$true, HelpMessage="AD Group identifier to pass to Get-ADGroup.")][string]$ADGroup,
[Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)][array]$ExpectedList,
[switch]$NoRemove,
[switch]$ReportOnly
)

$ADGroupMembers = $(Get-ADGroup $ADGroup -Properties members).members
$compare = compare $ADGroupMembers $ExpectedList
$ToAdd = $($compare | ? sideindicator -eq '=>').inputobject
$ToRemove = $($compare | ? sideindicator -eq '<=').inputobject

if($ToAdd.count -ne 0)
{
Write-Output "DNs to add to '${ADGroup}':"
$ToAdd
if(-not $ReportOnly){$ToAdd | %{Add-ADGroupMember -Identity $ADGroup -Members $_ -Confirm}}
}
else
{
"Nothing to add to '${ADGroup}'."
}
if($ToRemove.count -ne 0)
{
"DNs to remove from '${ADGroup}':"
$ToRemove
if(-not $ReportOnly){$ToAdd | %{Add-ADGroupMember -Identity $ADGroup -Members $_ -Confirm}}
}
else
{
"Nothing to remove from '${ADGroup}.'"
}
}

$allRigPersonnel = (gci 'AD:\OU=Personnel,OU=Rigs,OU=All Users,DC=NOBLE,DC=CC' -Recurse | ? objectclass -eq 'user' | ? name -notlike 'noble*').distinguishedname
$ndorservers = gci 'AD:\OU=NDOR_Appliances,OU=Servers_,DC=NOBLE,DC=CC' -Recurse -Filter {objectclass=computer}


if (!(Get-PSDrive sccmSQLscripts -ea SilentlyContinue)){New-PSDrive -Name sccmSQLscripts -PSProvider FileSystem -Root '\\housccm\d$\ConfigMgr 2012 Scripts\SQL'}
$sql = gc 'sccmSQLscripts:\All Rig Computers.sql'
$conn = New-Object System.Data.SqlClient.SqlConnection(“server=housccm; database=cm_hou; Integrated Security=true”)
$conn.Open()
$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.Connection = $conn
$cmd.CommandText = $sql
$cmd = New-Object System.Data.SqlClient.SqlCommand($sql,$conn)
$ds = New-Object System.Data.DataSet
$da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.Fill($ds)
$conn.Close()
$dt = $ds.Tables[0]
$allRigComputers = $($dt | ? {$_.dn -like "*CC"}).dn

Set-ADGroupMembershipFromExpectedList -ADGroup 'All NDOR Users' -ExpectedList $allRigPersonnel -ReportOnly
Set-ADGroupMembershipFromExpectedList -ADGroup 'All NDOR Servers' -ExpectedList $ndorservers -ReportOnly
Set-ADGroupMembershipFromExpectedList -ADGroup 'All Rig Computers' -ExpectedList $allRigComputers -ReportOnly