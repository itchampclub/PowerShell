<#
.Synopsis
Gets group membership differences between two user accounts
.DESCRIPTION
Long description
.EXAMPLE
Get-GroupDiff Domain1\User Domain2\User -Verbose
Show what groups are missing, the same and extra in Domain1\User, using Domain2\User as a reference. Shows a little more information.
.EXAMPLE
Get-GroupDiff Domain1\User Domain2\User | ?{$_.Compare -eq "missing"} | select name
Get a list of groups that are missing in Domain1\User, using Domain2\User as a refernce.
#>
function Get-GroupDiff
{
[CmdletBinding()]
[Alias("GGD")]
[OutputType([psobject])]
Param
(
# The source user account - needs to be Domain\User
[Parameter(Mandatory=$true,Position=0)]
[string]$SourceUser,

# The user account that you are comparing to -Needs to be Domain\User
[Parameter(Position=1)]
[string]$DiffUser
)

Begin
{
if (!(Get-Module | Where-Object {$_.name -eq "activedirectory"})) 
{ 
try
{Import-Module activedirectory -ea stop}
catch [System.Exception]
{Write-Warning -Message "Can't load activedirectory module. You need RSAT installed.";break}}
if ($SourceUser.split("\")[1] -eq $null)
{
$SourceDomain = "source.com"
Write-Warning -Message "Source Username needs domain -- assuming $SourceDomain"
}
else
{
$SourceDomain = (Get-ADDomain $SourceUser.Split("\")[0]).dnsroot
$SourceUser = $SourceUser.Split("\")[1]
}
if ($DiffUser -eq ""){$DiffUser = $SourceUser}
if ($DiffUser.split("\")[1] -eq $null)
{
$DiffDomain = "dest.com"
Write-Warning -Message "Diff Username needs domain -- assuming $DiffDomain"
}
else
{
$DiffDomain = (Get-ADDomain $DiffUser.Split("\")[0]).dnsroot
$DiffUser = $DiffUser.Split("\")[1]
}


}
Process
{
$DiffMembers = Get-ADPrincipalGroupMembership -server $DiffDomain -Identity $DiffUser 
$SourceMembers = Get-ADPrincipalGroupMembership -server $SourceDomain -Identity $SourceUser 
Write-Verbose "$DiffDomain count: $($DiffMembers.count)"
Write-Verbose "$SourceDomain count: $($SourceMembers.count)"
$diff = Compare-Object -ReferenceObject $DiffMembers -DifferenceObject $SourceMembers -property name -IncludeEqual
}
End
{
$SourceDomain = (Get-ADDomain $SourceDomain).NetBIOSName
$diff | select @{N="GroupName"; E={$_.name}},@{N="Domain";E={$SourceDomain}},@{N="User";E={$SourceUser}},@{N="Compare";E={($_.sideindicator).replace("==","same").replace("=>","extra").replace("<=","missing")}}
}
}