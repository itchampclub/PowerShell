[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$computer = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername")
$Credential = $host.ui.PromptForCredential("Need credentials", "Please enter your user name and password for $computer", "eoc" , ""          )
