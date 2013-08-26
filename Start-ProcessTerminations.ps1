<#
.Synopsis
   Process terminated user accounts.
.DESCRIPTION
   Long description
.EXAMPLE
   Start-ProcessTerminations
.EXAMPLE
   Start-ProcessTerminations -SamAccountName jshmoe
.INPUTS
   Can accept a list of user accounts. 
.OUTPUTS
   Outputs errors (if any) or strings to paste into Termination Tickets.
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Start-ProcessTerminations
{
#region Finished and Tested
[CmdletBinding(DefaultParameterSetName='FromOU', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Low')]
    [OutputType([String[]])]
#region Parameters
param(

#Single account to process for termination. If not defined, a list will be generated of the Terminations OU from which to select.
[Parameter(Mandatory=$true,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true,
    ParameterSetName="Manual")]
[ValidateScript({([adsisearcher]"(&(samaccountname=$_))").FindOne() -ne $null})]
[Alias("ID")]
[Alias("sAMAccountName")]
[array]$Users,

#Set the archive root (default is \\houmailbk\Terminations$).
[ValidateScript({Test-Path $_ -PathType 'Container'})]
[String]$ArchiveRoot = "\\houmailbk\Terminations$",

#Set the OU from which to choose user accounts to process for termination. This will require verification before processing.
[Parameter(ParameterSetName="Default")]
[ValidateScript({[adsi]::Exists("LDAP://$_")})]
[Alias("FromOU")]
[Alias("OU")]
[string]$TerminationsOU = "ou=Terminations,ou=All Users,dc=Noble,dc=CC",

#Run against an ADUser.
[Parameter(Mandatory=$true,
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true,
    ParameterSetName="ADUser")]
[Microsoft.ActiveDirectory.Management.ADUser]$ObjectGUID,

#Remove user's homespace after archive.
[switch]$DeleteHomespace

)
#endregion Parameters

if($PSBoundParameters.debug.ispresent){
$error.exception.Message|%{Write-Debug $_}
$error.clear()
}
Write-Debug $PSCmdlet.ParameterSetName

if(!((gmo).Name.ToLower().Contains('activedirectory'))){Write-Error "Active Directory module needs to be loaded.";return}
if(!((Get-PSSession).ConfigurationName.ToLower().Contains('microsoft.exchange'))){Write-Error "Need to establish an implicit remoting session to exchange CAS.";return}

$GridColumns = 
    @{name="Logon";expression={$_.samaccountname}},
    @{name="Display Name";expression={$_.name}},
    @{name="Employee ID";expression={$_.employeeid}},
    @{name="Account Enabled";expression={$_.enabled}},
    @{name="Home Directory";expression={$_.homedirectory}},
    @{name="Mail Server";expression={$_.exchangeserver}},
    @{name="Exchange Version";expression={$_.exchangeserverversion}}

switch($PSCmdlet.ParameterSetName){
"Manual"
{
$Terminations=$users|%{Get-ADUser -Filter {samaccountname -eq $_} -Properties *}
}
"ADUser"
{
$Terminations = Get-ADUser $ObjectGUID -Properties *
}
default
{
$Terminations = Get-ADUser -SearchBase $TerminationsOU -Filter {objectClass -eq "User"} -Properties * # homedirectory,employeeID,msExchHomeServerName
}
}

$Terminations | ? msExchHomeServerName -NE $null | %{Add-Member -InputObject $_ -PassThru -Type NoteProperty -Name ExchangeServer -Value $($_.msExchHomeServerName.split('/')) -Force}|Out-Null
$Terminations | ? msExchHomeServerName -NE $null | %{Add-Member -InputObject $_ -PassThru -Type NoteProperty -Name ExchangeServer -Value $($_.ExchangeServer.GetValue($_.ExchangeServer.Count-1).tostring().replace('cn=','')) -Force}|Out-Null
$Terminations | ? msExchHomeServerName -NE $null | %{Add-Member -InputObject $_ -PassThru -Type NoteProperty -Name ExchangeServerVersion -Value $((Get-ExCAS_ExchangeServer $_.ExchangeServer).admindisplayversion) -Force}|Out-Null
$SelectedAccounts = $Terminations | select -Property $GridColumns | Out-GridView -OutputMode Multiple -Title "Select a verified account for termination:"
if($SelectedAccounts -eq $null){Write-Output 'No users selected.';return}

$QuarterDir = "$([datetime]::Now.Year) Q$([math]::Ceiling([datetime]::Now.Month/3))"
if(!(Test-Path $ArchiveRoot\$QuarterDir)){md $QuarterDir|out-null}

#endregion Finished and Tested

foreach($user in $SelectedAccounts)
{#begin foreach user
$username = $user.logon
$UserDir = "$ArchiveRoot\$QuarterDir\$username"
if(!(Test-Path $UserDir)){md $UserDir|out-null}

switch ($DeleteHomespace)
{
$false
{
#region Copy Homespace
if(!($user.'Home Directory' -eq $null))
    {
    if(Test-Path "$UserDir\homespace"){rni -Path "$UserDir\homespace" -NewName "$UserDir\homespace.pre-existing.$(get-date -f MM-dd-yy.HHmm)" |out-null} #Custom date and time format: http://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
    md -Path "$UserDir\homespace"|Out-Null
    $HomespaceSource = $user.'Home Directory'
    $sb = {Copy-Item -Recurse -Destination $args[0] -Path $args[1] -Verbose -Force}
    $argsList = ("$UserDir\homespace\",$HomespaceSource)
    Start-Job -Name "$username-homespace" -ScriptBlock $sb -ArgumentList $argsList|Out-Null
    }
#endregion Copy Homespace
}
$true
{
#region Move Homespace
if(!($user.'Home Directory' -eq $null))
    {
    if(Test-Path "$UserDir\homespace"){rni -Path "$UserDir\homespace" -NewName "$UserDir\homespace.pre-existing.$(get-date -f MM-dd-yy.HHmm)" |out-null} #Custom date and time format: http://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
    md -Path "$UserDir\homespace"|Out-Null
    $HomespaceSource = $user.'Home Directory'
    $sb = {Move-Item -Destination $args[0] -Path $args[1] -Verbose -Force}
    $argsList = ("$UserDir\homespace\",$HomespaceSource)
    Start-Job -Name "$username-homespace" -ScriptBlock $sb -ArgumentList $argsList|Out-Null
    }
#endregion Move Homespace
}
}
#region Export PST
if(!($user.'Exchange Version' -eq $null)) #check if user has mailbox
    {
    if($user.'Exchange Version'.Split(' ').GetValue(1) -gt 14) #check if above Exchange version 14
        {
    if(Test-Path "$UserDir\pst"){rni -Path "$UserDir\pst" -NewName "$UserDir\pst.pre-existing.$(get-date -f MM-dd-yy.HHmm)" |out-null}
    md -Path "$UserDir\pst"|Out-Null
        New-ExCAS_MailboxExportRequest -FilePath "$UserDir\pst\$username.pst" -Mailbox $username -Name "$username-archiveToPST"|Out-Null
        $loop = $true
        do
            {
            switch ($(Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST").status)
                {
                "Completed" {Write-Output "$username-archiveToPST Completed." ;$loop = $false}
                "CompletedWithWarning" {Write-Output "$username-archiveToPST Completed with warnings." ;$loop = $false}
                "Failed" {Write-Output "$username-archiveToPST Failed." ;$loop = $false}
                "Queued" {Write-Progress -Activity "Export mailbox $username to $UserDir\pst\$username.pst" -Status "Queued" -PercentComplete $((Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST"|Get-ExCAS_MailboxExportRequestStatistics).percentcomplete);sleep -Seconds 10}
                "InProgress" {Write-Progress -Activity "Export mailbox $username to $UserDir\pst\$username.pst" -Status "In Progress" -PercentComplete $((Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST"|Get-ExCAS_MailboxExportRequestStatistics).percentcomplete);sleep -Seconds 5}
                default {sleep -Seconds 5}
                }
            } while ($loop -eq $true)
        Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST" | Remove-ExCAS_MailboxExportRequest -Confirm:$false
        }
    }
#endregion Export PST

#region Disconnect Mailbox

#endregion Disconnect Mailbox

#region Delete Account

#endregion Delete Account

#region CleanUp


#endregion CleanUp

}#foreach user
}#function end