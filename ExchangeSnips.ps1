get-wmiobject win32_logicaldisk -filter "drivetype=3" -computername cos8aex07,cos8aex12 | select-object systemname,deviceid,@{Expression={($_.freespace/1GB).tostring("0.00")};Label="Freespace in GB"},@{Expression={($_.size/1GB).tostring("0.00")};Label="Size in GB"}|fl

[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',"COS8AEX06").OpenSubKey("SOFTWARE\\Microsoft\\Exchange\\Setup").GetValue("MsiInstallPath").replace(":","$")+"scripts\"

Get-ExchangeServer | Select-Object @{Expression={$_.name};Label="SystemName"},@{Expression={"\\"+$_.name+"\"+[Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$_.name).OpenSubKey("SOFTWARE\\Microsoft\\Exchange\\Setup").GetValue("MsiInstallPath").replace(":","$")+"scripts\"};Label="Path"} | select-object systemname,path,@{Expression={get-childitem -path $_.path -Filter "experfwiz.*"};Label="Filter"}

Get-Content C:\tech\ServerLoggingList.txt | foreach {$wmi = get-WmiObject win32_service -ComputerName $_ -Filter "name='uwin_ms'" -errorAction silentlyContinue; if(-not $wmi){"cannot connect to $_"} else {$wmi.systemname+","+$wmi.caption+","+$wmi.state+","+$wmi.startmode+","+$wmi.startname}}

get-exchangeserver | foreach-object {Get-WmiObject win32_operatingsystem -computername $_.name | Select-Object @{Expression={$_.csname};Label="System Name"},@{Expression={[System.Management.ManagementDateTimeconverter]::ToDateTime($_.LastBootUpTime)};Label="Boot Time"}}

Get-WmiObject win32_operatingsystem -computername MDS8AEO03,MDS8AEO04 | Select-Object @{Expression={$_.csname};Label="System Name"},@{Expression={[System.Management.ManagementDateTimeconverter]::ToDateTime($_.LastBootUpTime)};Label="Boot Time"}
