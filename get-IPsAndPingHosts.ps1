$systems = Import-Csv 'H:\systems without client.csv'
$systems |? ip_from_name -EQ ""| %{ Add-Member -inputObject $_ -passThru -type NoteProperty -name IP_From_Name -Value $(try{[system.net.dns]::GetHostByName($_.System).AddressList.GetValue(0).ToString()}catch{""}) -Force}
$systems |? ip_from_name -NE ""|? pingable -NE "Success"| %{ Add-Member -inputObject $_ -passThru -type NoteProperty -name Pingable -Value $(try{(New-Object System.Net.NetworkInformation.Ping).send([System.Net.IPAddress]$_.IP_From_Name).Status.ToString()}catch{""}) -Force}
$systems | select system,ad_site,ip_from_name,pingable,finished,notes,os | ConvertTo-Csv | Out-File 'H:\systems without client.csv'

