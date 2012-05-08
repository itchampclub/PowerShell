# Setting up the SQL Data Adapter
$Adapter = New-Object System.Data.SqlClient.SqlDataAdapter
$Adapter.SelectCommand = New-Object System.Data.SqlClient.SqlCommand
$Adapter.SelectCommand.Connection = New-Object System.Data.SqlClient.SqlConnection

# Declare NodesDS as a DataSet
$NodesDS = New-Object System.Data.DataSet

$Adapter.SelectCommand.Connection.ConnectionString = "server=hou-nms02;database=orion;trusted_connection=true;"

# This is the SQL query for Solarwinds to give me all the nodes that are defined as GlobalView that are on 
# the Houston server but not on the Massy server in France. We will use the defined IP_Address collumn to
# ping the systems from the Orion servers to verify that they can be reached from both servers.
$Adapter.SelectCommand.CommandText = "
SELECT LN.* 
FROM Nodes AS LN 
--We will do a left outer join that will result in NULLs returned for rows not matched.
LEFT OUTER JOIN 
--Joining to a linked server in France
massy.solarwindsorion.dbo.nodes AS RN 
--Since the remote server is collated to French_CI_AS, we need to tell the join
--to treat it like the same as the local system.
ON LN.IP_Address = RN.IP_Address COLLATE SQL_Latin1_General_CP1_CI_AS 
WHERE (RN.Caption IS NULL) 
AND (LN.GlobalView = 1) 
AND (LN.UnManaged = 0) 
ORDER BY LN.Caption"
$Adapter.Fill($NodesDS)

# I was testing the script on a CSV file. The collumn headers become the properties when you ConvertFrom-Csv.
# $Nodes = Get-Content v:\Nodes.csv | ConvertFrom-Csv

# We'll ping the systems from these servers remotely.
$Sources = @("hou-nms01","msy-nms01")

# I need to loop these because I want to handle the errors that return.
foreach ($Node in $NodesDS.Tables[0]) {
foreach ($Source in $Sources) {
  Trap {
        #write-warning ($Source+" reported: "+$_.Exception.Message)
	write-host ($Node.Caption+" ("+$node.IP_Address+") cannot be reached from "+$Source) -foregroundColor RED
        Continue
    }
   # The Test-Connection Cmdlet allows you to specify a source computer to ping from remotely. It also has methods for
   # allowing you to control the various aspects of the ping process and define credentials of a user that has the 
   # ability to ping on the remote system if your systems are locked down. In order to run this, you need to make sure 
   # that winrm is set up on the remote systems.
   if (Test-Connection -Source $Source -ComputerName $Node.IP_Address -erroraction stop  ) {
     write-host ($Node.Caption+" ("+$node.IP_Address+") UP from "+$Source) -foregroundColor Green
   }
   else {
     write-host ($Node.Caption+" ("+$node.IP_Address+") cannot be reached from "+$Source) -foregroundColor RED
   }
 }
 }
 #Cleanup
 Remove-Variable -Name Adapter,Node,Nodes,NodesDS,Source,Sources