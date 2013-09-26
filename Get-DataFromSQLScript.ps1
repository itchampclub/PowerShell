
[CmdletBinding()]
param(
[Parameter(Mandatory=$true)]
#[ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1})]
[string]$server,

[Parameter(Mandatory=$true,ParameterSetName="File")]
[ValidateScript({Test-Path -Path $_ -PathType Leaf})]
[Alias("file","script")]
[string]$path,

[Parameter(Mandatory=$true,ParameterSetName="SQL")]
[Alias("command")]
[string]$sql,

[Parameter(Mandatory=$false)]
[ValidateScript({$true})]
#[Alias("db")]
[string]$database="master"

)
begin{
try{
$conn = New-Object System.Data.SqlClient.SqlConnection(“server=$server; database=$database; Integrated Security=true”)
$conn.Open()
}
catch [exception]
{
throw $_.exception.message
}
}
process{
try{
$cmd = New-Object System.Data.SqlClient.SqlCommand
$cmd.Connection = $conn
switch ($PSCmdlet.ParameterSetName)
{
    'File' {$cmd = New-Object System.Data.SqlClient.SqlCommand($(Get-Content $path),$conn)}
    'SQL'  {$cmd = New-Object System.Data.SqlClient.SqlCommand($sql,$conn)}
}
$ds = New-Object System.Data.DataSet
$da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
[void]$da.Fill($ds)

$dt = $ds.Tables[0]
$dt
}
catch [Exception]
{
return $_.exception.message 
}
}
end{
$conn.Close()
}