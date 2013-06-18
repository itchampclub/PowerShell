Function Get-OUsForm 
{
param(
[String]
$FromOU="OU=All Users,DC=NOBLE,DC=CC"
,
[String]
$ObjectClass="OrganizationalUnit"
,
[String]
$Properties="distinguishedName"
,
[Switch]
$Rigs
)
if ($Rigs){$FromOU = "OU=Personnel,OU=Rigs,OU=All Users,DC=NOBLE,DC=CC"}
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | out-null
$WinForm = new-object Windows.Forms.Form   
$WinForm.text = "ListBox Control"
$WinForm.Size = new-object Drawing.Size(300,100)
$ListBox = new-object Windows.Forms.combobox
$WinForm.controls.add($listbox)
$OUs = gci AD:\$FromOU -Properties $Properties | ?{$_.ObjectClass -eq $ObjectClass}
foreach ($OU in $OUs)
{
$ListBox.Items.Add($OU) | Out-Null
}
$ListBox.DisplayMember = "Name"
$ListBox.SelectedIndex = 0
$Button = new-object System.Windows.Forms.Button
$Button.Location = new-object System.Drawing.Size(150,0)
$Button.Size = new-object System.Drawing.Size(50,20)
$Button.Text = "OK"
$Button.Add_Click({
$WinForm.Close()

})

$WinForm.Controls.Add($Button)

$WinForm.Add_Shown($WinForm.Activate())
$WinForm.showdialog() | out-null 
$ListBox.SelectedItem
} #end function Get-AllUsersOUsListBox

#Get-OUsForm
