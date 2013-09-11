$Systems = (Get-ADComputer -Filter {OperatingSystem -like '*server*'}).name

   1 Get-ADComputer                                                                                                                                                   
   2 Get-ADComputer -Filter {OperatingSystem -like '*server*' }                                                                                                       
   3 (Get-ADComputer -Filter {OperatingSystem -like '*server*'}).count                                                                                                
   4 (Get-ADComputer -Filter {OperatingSystem -like '*server*'}).name                                                                                                 
   5 $Systems = (Get-ADComputer -Filter {OperatingSystem -like '*server*'}).name...                                                                                   
   6 $Systems                                                                                                                                                         
   7 $Systems | foreach{Test-Connection -AsJob -cn $_ -Count 1}                                                                                                       
   8 Get-Job                                                                                                                                                          
   9 clear                                                                                                                                                            
  10 Get-Job -State failed                                                                                                                                            
  11 Get-Job -State failed | Receive-Job                                                                                                                              
  12 Get-Job -State failed | Remove-Job                                                                                                                               
  13 Get-Job -State NotStarted                                                                                                                                        
  14 Get-Job -State Running                                                                                                                                           
  15 Get-Job | Receive-Job -Keep                                                                                                                                      
  16 $results = Get-Job | Receive-Job -Keep                                                                                                                           
  17 $results                                                                                                                                                         
  18 $results = Get-Job | Receive-Job                                                                                                                                 
  19 Get-Job -HasMoreData                                                                                                                                             
  20 Get-Job -HasMoreData $true                                                                                                                                       
  21 Get-Job -HasMoreData $false | Remove-Job                                                                                                                         
  22 Get-Job                                                                                                                                                          
  23 $results.Count                                                                                                                                                   
  24 $results| gm                                                                                                                                                     
  25 $results | sort                                                                                                                                                  
  26 $results| gm                                                                                                                                                     
  27 $results| gm | ft -AutoSize                                                                                                                                      
  28 $results| gm | fl                                                                                                                                                
  29 $results|select *                                                                                                                                                
  30 $results|select *|gm                                                                                                                                             
  31 $results|? statuscode -eq 0                                                                                                                                      
  32 $results|? statuscode -ne 0                                                                                                                                      
  33 $results|? statuscode -eq 0                                                                                                                                      
  34 $results|? statuscode -eq 0 | mo                                                                                                                                 
  35 $results|? statuscode -eq 0 | measure                                                                                                                            
  36 ($results|? statuscode -eq 0).name                                                                                                                               
  37 ($results|? statuscode -eq 0).nameIPV4Address                                                                                                                    
  38 ($results|? statuscode -eq 0).IPV4Address                                                                                                                        
  39 ($results|? statuscode -eq 0).IPV4Address.tostring()                                                                                                             
  40 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString.tostring()                                                                                           
  41 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString                                                                                                      
  42 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString|mg                                                                                                   
  43 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString|gm                                                                                                   
  44 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString.ToString()                                                                                           
  45 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString.ToString()|gm                                                                                        
  46 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString                                                                                                      
  47 ($results|? statuscode -eq 0).IPV4Address.IPAddressToString|foreach{gwmi -Namespace "root\cimv2" -Class "__Namespace" -cn $_ -AsJob}                             
  48 get-job -State NotStarted                                                                                                                                        
  49 get-job -State Failed                                                                                                                                            
  50 get-job -State Failed | Remove-Job                                                                                                                               
  51 get-job -State Running                                                                                                                                           
  52 get-job -State Running                                                                                                                                           
  53 get-job -State Running                                                                                                                                           
  54 get-job -State Running                                                                                                                                           
  55 get-job -State Running                                                                                                                                           
  56 get-job -State Running                                                                                                                                           
  57 get-job -State Running                                                                                                                                           
  58 get-job -State Running                                                                                                                                           
  59 get-job -State Completed                                                                                                                                         
  60 get-job -State Completed | Receive-Job -Keep                                                                                                                     
  61 get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell'                                                                                                 
  62 get-job -State Running                                                                                                                                           
  63 get-job -State Running                                                                                                                                           
  64 get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell'                                                                                                 
  65 get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell'                                                                                                 
  66 get-job -State Running                                                                                                                                           
  67 get-job -State Running                                                                                                                                           
  68 get-job -State Running                                                                                                                                           
  69 get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell'                                                                                                 
  70 (get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell').PSCopmutername                                                                                
  71 (get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell').PSComputername                                                                                
  72 (get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell').PSComputername                                                                                
  73 get-job -State Running                                                                                                                                           
  74 get-job -State Running                                                                                                                                           
  75 get-job -State Running                                                                                                                                           
  76 get-job -State Running|measure                                                                                                                                   
  77 get-job -State Running|measure                                                                                                                                   
  78 get-job -State Running|measure                                                                                                                                   
  79 get-job -State Running|measure                                                                                                                                   
  80 get-job -State Running                                                                                                                                           
  81 get-job -State Running | Receive-Job -Keep                                                                                                                       
  82 get-job -State Running|measure                                                                                                                                   
  83 get-job -State Running | Stop-Job                                                                                                                                
  84 get-job -State Running                                                                                                                                           
  85 get-job -State Stopped                                                                                                                                           
  86 get-job -State Stopped|Remove-Job                                                                                                                                
  87 get-job -State Stopped                                                                                                                                           
  88 get-job                                                                                                                                                          
  89 get-job -State Failed                                                                                                                                            
  90 get-job -State Failed|Remove-Job                                                                                                                                 
  91 (get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell').PSComputername                                                                                
  92 $DellServers = (get-job -State Completed | Receive-Job -Keep | ? name -eq 'Dell').PSComputername                                                                 
  93 $DellServers|gm                                                                                                                                                  
  94 $DellServers.count                                                                                                                                               
  95 $DellServers|foreach{gwmi -AsJob -Namespace root\cimv2\dell -Class Dell_RemoteAccessServicePort -cn $_ -Property accessinfo,systemname}                          
  96 get-job -State Completed | Receive-Job -Keep                                                                                                                     
  97 get-job                                                                                                                                                          
  98 get-job|Remove-Job                                                                                                                                               
  99 $DellServers|foreach{gwmi -AsJob -Namespace root\cimv2\dell -Class Dell_RemoteAccessServicePort -cn $_ -Property accessinfo,systemname}                          
 100 Get-Job                                                                                                                                                          
 101 Get-Job -HasMoreData $false                                                                                                                                      
 102 Get-Job -HasMoreData $false|Remove-Job                                                                                                                           
 103 Get-Job -State Running                                                                                                                                           
 104 Get-Job -State Failed                                                                                                                                            
 105 gj                                                                                                                                                               
 106 $results = get-job -State Completed | Receive-Job                                                                                                                
 107 $results                                                                                                                                                         
 108 $results|select * -ExcludeProperty _*                                                                                                                            
 109 $results|select acc*,sys*                                                                                                                                        
 110 $results|select acc*,*name*                                                                                                                                      
 111 $results|select acc*,*name*|sort -Unique                                                                                                                         
 112 $results|select acc*,*name*                                                                                                                                      
 113 $results.accessinfo                                                                                                                                              
 114 $results.accessinfo|sort -Unique                                                                                                                                 
 115 get=job                                                                                                                                                          
 116 Get-Job                                                                                                                                                          
 117 Get-Job -HasMoreData $false | Remove-Job                                                                                                                         
 118 Get-Job                      