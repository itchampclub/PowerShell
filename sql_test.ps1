if (!(Get-PSDrive sccmSQLscripts -ea SilentlyContinue)){New-PSDrive -Name sccmSQLscripts -PSProvider FileSystem -Root '\\housccm\d$\ConfigMgr 2012 Scripts\SQL'}

$sql = gc 'sccmSQLscripts:\All Systems with no client.sql'

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
$dt