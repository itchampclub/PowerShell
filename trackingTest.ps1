if (Test-Path H:\servers-ping.txt)
{
$computers = Get-Content "H:\servers-ping.txt"
}
elseif (Test-Path H:\servers-backup.txt)
{
$computers = @()
$computers += "system,status,time"
$computers += Get-Content "H:\servers-backup.txt"
$computers | Set-Content "H:\servers-ping.txt"
}
else
{
Write-Host "Files don't exist."
}

for ($i=1; $i -lt $computers.Length;$i++)
{
    $computer = $computers[$i].Split(",")
    if ($computer.Count -eq 1) {$computer += "down"}
    if ($computer[1] -eq "up") {continue}
    $ping = Test-Connection $computer[0] -Count 1
    if ($ping.StatusCode -eq 0)
    {
        $computers[$i]="$($computer[0].toupper().trim()),up,$($ping.ResponseTime.ToString())"
    }else{
        $computers[$i]="$($computer[0].toupper().trim()),down"
    }
    $computers | Set-Content "H:\servers-ping.txt"
}
$computers | ConvertFrom-Csv
