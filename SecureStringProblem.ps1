read-host -assecurestring | convertfrom-securestring | out-file C:\securestring.txt
$pass = cat C:\securestring.txt | convertto-securestring
$mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist "test",$pass
$mycred.GetNetworkCredential().Password
