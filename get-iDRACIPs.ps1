<# you need to set these values as Administrator
Set-Item wsman:.\localhost\MaxBatchItems -Value 100
Set-Item wsman:.\localhost\Client\AllowUnencrypted -Value $true
Set-Item wsman:.\localhost\Client\TrustedHosts -Value *
Set-Item wsman:.\localhost\Client\Auth\Basic -Value true
#>

function AddItemProperties($item, $properties, $output)
{
    if($item -ne $null)
    {
        foreach($property in $properties)
        {
            $propertyHash =$property -as [hashtable]
            if($propertyHash -ne $null)
            {
                $hashName=$propertyHash["name"] -as [string]
                if($hashName -eq $null)
                {
                    throw "there should be a string Name"  
                }
         
                $expression=$propertyHash["expression"] -as [scriptblock]
                if($expression -eq $null)
                {
                    throw "there should be a ScriptBlock Expression"  
                }
         
                $_=$item
                $expressionValue=& $expression
         
                $output | add-member -MemberType "NoteProperty" -Name $hashName -Value $expressionValue -Force
            }
            else
            {
                # .psobject.Properties allows you to list the properties of any object, also known as "reflection"
                foreach($itemProperty in $item.psobject.Properties)
                {
                    if ($itemProperty.Name -like $property)
                    {
                        $output | add-member -MemberType "NoteProperty" -Name $itemProperty.Name -Value $itemProperty.Value -Force
                    }
                }
            }
        }
    }
}
    
function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties, $Type)
{
    $output = new-object psobject

    if($Type -eq "AllInRight")
    {
        # This mix of rightItem with LeftProperties and vice versa is due to
        # the switch of Left and Right arguments for AllInRight
        AddItemProperties $rightItem $leftProperties $output
        AddItemProperties $leftItem $rightProperties $output
    }
    else
    {
        AddItemProperties $leftItem $leftProperties $output
        AddItemProperties $rightItem $rightProperties $output
    }
    $output
}

<#
.Synopsis
   Joins two lists of objects
.DESCRIPTION
   Joins two lists of objects
.EXAMPLE
   Join-Object $a $b "Id" ("Name","Salary")
#>
function Join-Object
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # List to join with $Right
        [Parameter(Mandatory=$true,
                   Position=0)]
        [object[]]
        $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true,
                   Position=1)]
        [object[]]
        $Right,

        # Condition in which an item in the left matches an item in the right
        # typically something like: {$args[0].Id -eq $args[1].Id}
        [Parameter(Mandatory=$true,
                   Position=2)]
        [scriptblock]
        $Where,

        # Properties from $Left we want in the output.
        # Each property can:
        # - Be a plain property name like "Name"
        # - Contain wildcards like "*"
        # - Be a hashtable like @{Name="Product Name";Expression={$_.Name}}. Name is the output property name
        #   and Expression is the property value. The same syntax is available in select-object and it is 
        #   important for join-object because joined lists could have a property with the same name
        [Parameter(Mandatory=$true,
                   Position=3)]
        [object[]]
        $LeftProperties,

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [Parameter(Mandatory=$true,
                   Position=4)]
        [object[]]
        $RightProperties,

        # Type of join. 
        #   AllInLeft will have all elements from Left at least once in the output, and might appear more than once
        # if the where clause is true for more than one element in right, Left elements with matches in Right are 
        # preceded by elements with no matches. This is equivalent to an outer left join (or simply left join) 
        # SQL statement.
        #  AllInRight is similar to AllInLeft.
        #  OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
        # match in Right. This is equivalent to a SQL inner join (or simply join) statement.
        #  AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
        # in right with at least one match in left, followed by all entries in Right with no matches in left, 
        # followed by all entries in Left with no matches in Right.This is equivallent to a SQL full join.
        [Parameter(Mandatory=$false,
                   Position=5)]
        [ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
        [string]
        $Type="AllInBoth"
    )

    Begin
    {
        # a list of the matches in right for each object in left
        $leftMatchesInRight = new-object System.Collections.ArrayList

        # the count for all matches  
        $rightMatchesCount = New-Object "object[]" $Right.Count

        for($i=0;$i -lt $Right.Count;$i++)
        {
            $rightMatchesCount[$i]=0
        }
    }

    Process
    {
        if($Type -eq "AllInRight")
        {
            # for AllInRight we just switch Left and Right
            $aux = $Left
            $Left = $Right
            $Right = $aux
        }

        # go over items in $Left and produce the list of matches
        foreach($leftItem in $Left)
        {
            $leftItemMatchesInRight = new-object System.Collections.ArrayList
            $null = $leftMatchesInRight.Add($leftItemMatchesInRight)

            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightItem=$right[$i]

                if($Type -eq "AllInRight")
                {
                    # For AllInRight, we want $args[0] to refer to the left and $args[1] to refer to right,
                    # but since we switched left and right, we have to switch the where arguments
                    $whereLeft = $rightItem
                    $whereRight = $leftItem
                }
                else
                {
                    $whereLeft = $leftItem
                    $whereRight = $rightItem
                }

                if(Invoke-Command -ScriptBlock $where -ArgumentList $whereLeft,$whereRight)
                {
                    $null = $leftItemMatchesInRight.Add($rightItem)
                    $rightMatchesCount[$i]++
                }
            
            }
        }

        # go over the list of matches and produce output
        for($i=0; $i -lt $left.Count;$i++)
        {
            $leftItemMatchesInRight=$leftMatchesInRight[$i]
            $leftItem=$left[$i]
                               
            if($leftItemMatchesInRight.Count -eq 0)
            {
                if($Type -ne "OnlyIfInBoth")
                {
                    WriteJoinObjectOutput $leftItem  $null  $LeftProperties  $RightProperties $Type
                }

                continue
            }

            foreach($leftItemMatchInRight in $leftItemMatchesInRight)
            {
                WriteJoinObjectOutput $leftItem $leftItemMatchInRight  $LeftProperties  $RightProperties $Type
            }
        }
    }

    End
    {
        #produce final output for members of right with no matches for the AllInBoth option
        if($Type -eq "AllInBoth")
        {
            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightMatchCount=$rightMatchesCount[$i]
                if($rightMatchCount -eq 0)
                {
                    $rightItem=$Right[$i]
                    WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties $Type
                }
            }
        }
    }
}

workflow GetFirmwareVersions
{
param
(
[string[]]$Computers,
[PSCredential]$cimCred
)
foreach -parallel ($Computer in $Computers){

inlinescript
    {
#   $cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials"
    $cimSO = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -Encoding Utf8 -UseSsl
    $cimOptions = @{
    Authentication = "Basic"
    Credential = $using:cimCred
    Port = "443"
    SessionOption = $cimSO
    }
    $pingable = Test-Connection -Count 1 -ComputerName $using:Computer -Quiet
    if ($pingable)
    {
    $cimSession = New-CimSession @cimOptions -ComputerName $using:Computer
    $cimSoftwareIdentity = Get-CimInstance -CimSession $cimSession -ResourceUri "http://schemas.dell.com/wbem/wscim/1/cim-schema/2/DCIM_SoftwareIdentity"
    $cimSoftwareIdentity # | ? {$_.Status -eq "Installed"} | ft PSComputerName, ELementName, VersionString
    }
    else
    {
    Select-Object -InputObject $using:computer -Property @{name='PSComputerName';expression={$using:computer}}
    }
    }
}
}

workflow GetiDRACjobs
{
param
(
[string[]]$Computers,
[PSCredential]$cimCred
)
foreach -parallel ($Computer in $Computers){

inlinescript
    {
#   $cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials"
    $cimSO = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -Encoding Utf8 -UseSsl
    $cimOptions = @{
    Authentication = "Basic"
    Credential = $using:cimCred
    Port = "443"
    SessionOption = $cimSO
    }
    $pingable = Test-Connection -Count 1 -ComputerName $using:Computer -Quiet
    if ($pingable)
    {
    $cimSession = New-CimSession @cimOptions -ComputerName $using:Computer
    $cimSoftwareIdentity = Get-CimInstance -CimSession $cimSession -ResourceUri "http://schemas.dell.com/wbem/wscim/1/cim-schema/2/DCIM_LifecycleJob"
    $cimSoftwareIdentity # | ? {$_.Status -eq "Installed"} | ft PSComputerName, ELementName, VersionString
    }
    else
    {
    Select-Object -InputObject $using:computer -Property @{name='PSComputerName';expression={$using:computer}}
    }
    }
}
}

workflow GetIdracIPs
{
param
(
[string[]]$VMHosts,
[string[]]$VIServer
)

$VMHosts = InlineScript
{
Add-PSSnapin vmware.vimautomation.core 
Connect-VIServer $using:VIServer | Out-Null
(Get-VMHost).name
}
foreach -parallel ($VMHost in $VMHosts){
inlinescript
{
Add-PSSnapin vmware.vimautomation.core 
Connect-VIServer $using:VIServer | Out-Null
function Get-VMHostWSManInstance {
param (
[Parameter(Mandatory=$TRUE,HelpMessage="VMHosts to probe")]
[VMware.VimAutomation.Client20.VMHostImpl[]]
$VMHost,

[Parameter(Mandatory=$TRUE,HelpMessage="Class Name")]
[string]
$class,

[switch]
$ignoreCertFailures,

[System.Management.Automation.PSCredential]
$credential=$null
)

$omcBase = "http://schema.omc-project.org/wbem/wscim/1/cim-schema/2/"
$dmtfBase = "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/"
$vmwareBase = "http://schemas.vmware.com/wbem/wscim/1/cim-schema/2/"

if ($ignoreCertFailures) {
$option = New-WSManSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
} else {
$option = New-WSManSessionOption
}
foreach ($H in $VMHost) {
if ($credential -eq $null) {
$hView = $H | Get-View -property Value
$ticket = $hView.AcquireCimServicesTicket()
$password = convertto-securestring $ticket.SessionId -asplaintext -force
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $ticket.SessionId, $password
}
$uri = "https`://" + $h.Name + "/wsman"
if ($class -cmatch "^CIM") {
$baseUrl = $dmtfBase
} elseif ($class -cmatch "^OMC") {
$baseUrl = $omcBase
} elseif ($class -cmatch "^VMware") {
$baseUrl = $vmwareBase
} else {
throw "Unrecognized class"
}
Get-WSManInstance -Authentication basic -ConnectionURI $uri -Credential $credential -Enumerate -Port 443 -UseSSL -SessionOption $option -ResourceURI "$baseUrl/$class"
}

}
$thisVMhost = Get-VMHost $using:VMhost
if ($thisVMhost.connectionstate -eq "Connected")
{
$iDRAC = Get-VMHostWSManInstance -VMHost $thisVMHost -class OMC_IPMIIPProtocolEndpoint -ignoreCertFailures
$pingable = Test-Connection -ComputerName $iDRAC.IPv4Address -Quiet -Count 1
}
#Write-Output "$($thisVMhost.name),$($iDRAC.IPv4Address),$($iDRAC.MACAddress)"
Select-Object -InputObject $thisVMhost -Property name,connectionstate,@{name='iDRAC_IP'; expression={$iDRAC.IPv4Address}},@{name='iDRAC_MAC'; expression={$iDRAC.MACAddress}},@{name='pingable'; expression={$pingable.ToString()}}
}
}
}

Add-PSSnapin vmware.vimautomation.core
<# -Things to run

$hourigvcs = GetIdracIPs -VIServer hourigvcs
$cimCred = Get-Credential -UserName "root" -Message "iDRAC Credentials"
$hourigvcsFW = GetFirmwareVersions -Computers $hourigvcs.idrac_ip -cimCred $cimCred
$hourigvcsIDRACJobs = GetiDRACjobs -Computers $hourigvcs.idrac_ip -cimCred $cimCred
$hourigvcs = $hourigvcs | select * -Exclude ps*
$hourigvcsfw = $hourigvcsfw | Select @{name='iDRAC_IP';expression={$_.pscomputername}},* -ExcludeProperty ps*,cim*
$hourigvcsIDRACJobs = $hourigvcsIDRACJobs | ?{$_.name -ne "clearall"} | Sort-Object name | Select @{name='iDRAC_IP';expression={$_.pscomputername}},@{name='JobName';expression={$_.name}},* -exclude ps*
$hourigvcsjoinFW = Join-Object $hourigvcs $hourigvcsFW {$args[0].idrac_ip -eq $args[1].idrac_ip} * idrac*,element*,version*,status

#>