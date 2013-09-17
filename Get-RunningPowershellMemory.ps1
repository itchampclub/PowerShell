$Processes = get-process powershell* | Group-Object -Property ProcessName
foreach($Process in $Processes)
{
    $Obj = New-Object psobject
    $Obj | Add-Member -MemberType NoteProperty -Name Name -Value $Process.Name
    $ExecutionContext.Host.EnterNestedPrompt()
    $Obj | Add-Member -MemberType NoteProperty -Name WorkingSetInMegs -Value (($Process.Group|Measure-Object WorkingSet -Sum).Sum/1MB)
    $Obj    
}