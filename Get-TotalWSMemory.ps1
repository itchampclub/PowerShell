<#
.Synopsis
Get aggregate working set memory utilization for processes.
.EXAMPLE
Get-Process | sort processname -Unique | select ProcessName | .\Get-TotalWSMemory.ps1 | ft name, @{n='WS in MB';e={"{0:N2} MB" -f $($_.WorkingSetTotal/1MB)};align='right'}
#>
param(
[Parameter(ValueFromPipelineByPropertyName=$true,
ValueFromPipeline=$true)]
[string[]]$ProcessName = "*"
)
begin{}
process
{
$Processes = get-process $ProcessName | Group-Object -Property ProcessName
foreach($Process in $Processes)
{
    $Obj = New-Object psobject
    $Obj | Add-Member -MemberType NoteProperty -Name Name -Value $Process.Name
    $Obj | Add-Member -MemberType NoteProperty -Name WorkingSetTotal -Value (($Process.Group|Measure-Object WorkingSet -Sum).Sum)
    $Obj
}
}
end{}