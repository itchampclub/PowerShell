$systems = Import-Csv 'H:\systems without client.csv' -Header "System","OS","AD_Site"
$systems | %{ Add-Member -inputObject $_ -passThru -type NoteProperty -name IP_From_Name -Value $(try{[system.net.dns]::GetHostByName($_.System).AddressList.GetValue(0).ToString()}catch{""}) -Force}
$systems | %{ Add-Member -inputObject $_ -passThru -type NoteProperty -name Pingable -Value $(try{(New-Object System.Net.NetworkInformation.Ping).send([System.Net.IPAddress]$_.IP_From_Name).Status.ToString()}catch{""}) -Force}
