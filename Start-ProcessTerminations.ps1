function Start-ProcessTerminations
{
	<#
    .Synopsis
       Process terminated user accounts.
    .DESCRIPTION
    .EXAMPLE
       Start-ProcessTerminations

       Generates a list from Terminations OU so that you can select which ones to process.
    .EXAMPLE
       Start-ProcessTerminations -ID jshmoe

       Run Script against a single user.
    .INPUTS
       Can accept a list of user accounts. 
    .OUTPUTS
       Outputs errors (if any) or strings to paste into Termination Tickets.
    #>
	[CmdletBinding(
	DefaultParameterSetName='FromOU', 
	SupportsShouldProcess=$true, 
	PositionalBinding=$false,
	HelpUri = 'http://www.microsoft.com/',
	ConfirmImpact='Low')]
	[OutputType([String[]])]
	#region Parameters
	param(
	
	#Single account to process for termination. If not defined, a list will be generated of the Terminations OU from which to select.
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true,
	ParameterSetName="Manual")]
	[ValidateScript({([adsisearcher]"(&(samaccountname=$_))").FindOne() -ne $null})]
	[Alias("ID")]
	[Alias("sAMAccountName")]
	[array]$Users,
	
	#Set the archive root (default is \\houmailbk\Terminations$).
	[ValidateScript({Test-Path $_ -PathType 'Container'})]
	[String]$ArchiveRoot = "\\houmailbk\Terminations$",
	
	#Set the OU from which to choose user accounts to process for termination. This will require verification before processing.
	[Parameter(ParameterSetName="Default")]
	[ValidateScript({[adsi]::Exists("LDAP://$_")})]
	[Alias("FromOU")]
	[Alias("OU")]
	[string]$TerminationsOU = "ou=Terminations,ou=All Users,dc=Noble,dc=CC",
	
	#Run against an ADUser.
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$true,
	ValueFromPipelineByPropertyName=$true,
	ParameterSetName="ADUser")]
	[Microsoft.ActiveDirectory.Management.ADUser]$ObjectGUID,
	
	#Remove user's homespace after archive.
	[switch]$DeleteHomespace=$true,
	
	#Disable mailbox of account and remove exchnage properties.
	[switch]$DisableMailbox=$true,
	
	#Delete account
	[switch]$DeleteAccount=$true
	
	)
	#endregion Parameters
	BEGIN {#begin start
		Write-Debug "Begin Section Start"
		
		if($PSBoundParameters.debug.ispresent){
			$error.exception.Message|%{Write-Debug $_ -ea Ignore}
		}
		
		
		$error.clear()
		
		if (($DisableMailbox -eq $false) -and ($DeleteAccount -eq $true)){throw "Cannot delete account without disabling mailbox."}
		
		Write-Debug "Parameter Set: $PSCmdlet.ParameterSetName"
		
		if(!((gmo).Name.ToLower().Contains('activedirectory'))){Write-Error "Active Directory module needs to be loaded.";return}
		if(!((Get-PSSession).ConfigurationName.ToLower().Contains('microsoft.exchange'))){Write-Error "Need to establish an implicit remoting session to exchange CAS.";return}
		$GetProperties = "homedirectory","employeeID","msExchHomeServerName","enabled","targetAddress"
		$GridColumns = 
		@{name="Logon";expression={$_.samaccountname}},
		@{name="Display Name";expression={$_.name}},
		@{name="Employee ID";expression={$_.employeeid}},
		@{name="Account Enabled";expression={$_.enabled}},
		@{name="Home Directory";expression={$_.homedirectory}},
		@{name="Mail Server";expression={$_.exchangeserver}},
		@{name="Exchange Version";expression={$_.exchangeserverversion}},
		@{name="Office 365 User";expression={$_.O365}}
		
	}#begin end
	PROCESS {#process start
		Write-Debug "Process Section Start"
		
		switch($PSCmdlet.ParameterSetName)
		{
			"Manual"
			{
				$Terminations=$users|%{Get-ADUser -Filter {samaccountname -eq $_} -Properties $GetProperties}
			}
			"ADUser"
			{
				$Terminations = Get-ADUser $ObjectGUID -Properties $GetProperties
			}
			default
			{
				$Terminations = Get-ADUser -SearchBase $TerminationsOU -Filter {objectClass -eq "User"} -Properties $GetProperties
			}
		}
		
		#region Preprocessing
		Write-Debug "Pre-processing start"
		
		$HSWarning = (New-Object -ComObject wscript.shell).popup("Do not archive homespaces that are outside US.",300,"Homeshare Warning",0x1131)
		if($HSWarning -ne 1){"Please read and accept warning.";return}
		
		if($Terminations -eq $null){Write-Output 'No users were returned from internal query.';return}
		#There are more efficient ways to do this, but I want very fine control over debugging.
		$NewNoteMemberFalse=@{PassThru=$true;Type='NoteProperty';Force=$true;Value=$false}
		$NewNoteMemberTrue=@{PassThru=$true;Type='NoteProperty';Force=$true;Value=$true}
		$NewNoteMember=@{PassThru=$true;Type='NoteProperty';Force=$true}
		$NewScriptMember=@{PassThru=$true;Type='ScriptProperty';Force=$true}
		$ExchServers=Get-ExCAS_ExchangeServer
		
		$Terminations |
		Add-Member @NewScriptMember -Name ExchangeServer -Value {$(if($this.msExchHomeServerName -ne $null){$this.msExchHomeServerName.split('=').getvalue($this.msExchHomeServerName.split('=').count-1).tostring()}else{$false})}|
		Add-Member @NewScriptMember -Name ExchangeServerVersion -Value {$(if($this.ExchangeServer -ne $false){($ExchServers|? name -eq $this.ExchangeServer).admindisplayversion.Split(' ').GetValue(1)}else{$false})}|
		Add-Member @NewScriptMember -Name O365 -Value {$(try{($this.targetAddress -match '@noblecorp1.mail.onmicrosoft.com')}catch{$false})}|
		Out-Null
		
		$SelectedAccounts = $Terminations | select -Property $GridColumns | Out-GridView -OutputMode Multiple -Title "Select a verified account for termination:"
		if($SelectedAccounts -eq $null){Write-Output 'No users selected.';return}
		
		$SelectedAccounts |
		Add-Member @NewScriptMember -Name "HasHomeDirectory" -Value {$(if($this.'home directory' -ne $null){Test-Path $this.'home directory'}else{$false})}|
		Add-Member @NewScriptMember -Name "ExchangeOver2010" -Value {$(if($this.'exchange version' -gt 14){$true}else{$false})}|
		Add-Member @NewNoteMember -Name "HomespaceMessage" -Value "Homespace archival did not process."|
		Add-Member @NewNoteMember -Name "MailboxArchiveMessage" -Value "Mailbox archival did not process."|
		Add-Member @NewNoteMember -Name "MailboxDisableMessage" -Value "Mailbox disabling did not process."|
		Add-Member @NewNoteMember -Name "AccountDeletedMessage" -Value "Account deletion did not process."|
		Out-Null
		
		<# For testing preprocessing of account
        $SelectedAccounts | Out-GridView
        return
        #>
		
		#Create a new directory for the year quarter if it doesn't exist.
		$QuarterDir = "$([datetime]::Now.Year) Q$([math]::Ceiling([datetime]::Now.Month/3))"
		if(!(Test-Path $ArchiveRoot\$QuarterDir)){md $QuarterDir -ea ignore|out-null}
		
		#endregion Preprocessing
		
		foreach($user in $SelectedAccounts)
		{#begin foreach user
			Write-Progress -id 0 -Activity "Processing User accounts." -Status "Current account: $($user.logon)" -PercentComplete $(($(try{$SelectedAccounts.IndexOf($user)}catch{0})/$($SelectedAccounts.count+1))*100)
			
			$username = $user.logon
			$UserDir = "$ArchiveRoot\$QuarterDir\$username"
			if(!(Test-Path $UserDir)){md $UserDir|out-null}
			
			#region homespace
			if($user.HasHomeDirectory)
			{
				if(Test-Path "$UserDir\homespace"){rni -Path "$UserDir\homespace" -NewName "$UserDir\homespace.pre-existing.$(get-date -f MM-dd-yy.HHmm)" |out-null} #Custom date and time format: http://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx
				md -Path "$UserDir\homespace"|Out-Null
				$HomespaceSource = $user.'Home Directory'
				switch ($DeleteHomespace)
				{
					$false
					{$sb = {Copy-Item -Destination $args[0] -Path $args[1] -Force -Recurse}}
					$true
					{$sb = {Move-Item -Destination $args[0] -Path $args[1] -Force}}
				}
				$argsList = ("$UserDir\homespace\",$HomespaceSource)
				Start-Job -Name "$username-homespace" -ScriptBlock $sb -ArgumentList $argsList|Out-Null
				$user.HomespaceMessage = "Homespace archival processing job started."
			}
			else
			{
				$user.HomespaceMessage = "User does not have homespace."
			}
			#endregion homespace
			
			#region Export PST
			if($user.ExchangeOver2010)
			{
				if(Test-Path "$UserDir\pst"){rni -Path "$UserDir\pst" -NewName "$UserDir\pst.pre-existing.$(get-date -f MM-dd-yy.HHmm)" |out-null}
				md -Path "$UserDir\pst"|Out-Null
				if((Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST") -eq $null)
				{
					New-ExCAS_MailboxExportRequest -FilePath "$UserDir\pst\$username.pst" -Mailbox $username -Name "$username-archiveToPST"|Out-Null
					$user.MailboxArchiveMessage = "Mailbox archival has started."
				}
				else
				{
					$user.MailboxArchiveMessage = "Mailbox archival was already run."
				}
				$loop = $true
				do
				{
					switch ($(Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST").status)
					{
						"Completed"
						{
							$user.MailboxArchiveMessage = "Mailbox archival to $UserDir\pst\$username.pst is complete."
							$loop = $false
						}
						"CompletedWithWarning"
						{
							$user.MailboxArchiveMessage = "Mailbox archival to $UserDir\pst\$username.pst completed with warnings."
							$loop = $false
						}
						"Failed"
						{
							$user.MailboxArchiveMessage = "Mailbox archival to $UserDir\pst\$username.pst failed."
							$loop = $false
						}
						"Queued"
						{
							Write-Progress -Id 1 -Activity "Export mailbox $username to $UserDir\pst\$username.pst" -Status "Queued" -PercentComplete $((Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST"|Get-ExCAS_MailboxExportRequestStatistics).percentcomplete)
							sleep -Seconds 10
						}
						"InProgress"
						{
							Write-Progress -Id 1 -Activity "Export mailbox $username to $UserDir\pst\$username.pst" -Status "In Progress" -PercentComplete $((Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST"|Get-ExCAS_MailboxExportRequestStatistics).percentcomplete)
							sleep -Seconds 5
						}
						default
						{
							sleep -Seconds 5
						}
					}
				} while ($loop -eq $true)
			}
			else
			{
				$user.MailboxArchiveMessage = "No mailbox."
				
			}
			#endregion Export PST
			
			#region CleanUp and Wait
			
			Get-ExCAS_MailboxExportRequest -Name "$username-archiveToPST" | Remove-ExCAS_MailboxExportRequest -Confirm:$false
			if($(Get-Job $username-homespace -ea ignore) -ne $null)
			{
				Get-Job $username-homespace -ea Ignore | Wait-Job |Out-Null
				$error.Clear()
				Receive-Job $username-homespace
				if($error.Count -eq 0)
				{
					$user.homespacemessage = "Homespace $HomespaceSource has been archived to $UserDir\homespace\."
				}
				else
				{
					$user.homespacemessage = "Homespace $HomespaceSource has been archived, but with errors."
					$error.Clear()
				}
			}
			
			#endregion CleanUp and Wait
			
			#region Disable Mailbox
			switch($DisableMailbox)
			{
				$true
				{
					if($user.ExchangeOver2010)
					{
						if($error.Count -eq 0)
						{
							Disable-ExCAS_Mailbox $username -Confirm:$false|Out-Null
							$user.MailboxDisableMessage = "Mailbox has been disabled on $($user.'Mail Server')."
						}
						else
						{
							$user.MailboxDisableMessage = "Errors were detected in script, ${username}'s Mailbox will not be Disabled."
							Write-Warning $user.MailboxDisableMessage
							$error.exception.message|%{Write-Warning "Error: ${username}: $($_)"}
							#$error.Clear()
						}
					}
				}
			}#end Disable Mailbox Switch
			#endregion Disable Mailbox
			
			#region Delete Account
			switch($DeleteAccount)
			{
				$true
				{
					if($error.Count -eq 0)
					{
						if(!($user.O365))
						{
							Remove-ADUser $username -Confirm:$false|Out-Null
							$user.AccountDeletedMessage = "AD account has been deleted."
						}
						else
						{
							$user.AccountDeletedMessage = "Account uses Office 365 Mailbox. AD account has not been deleted."
						}
					}
					else
					{
						$user.AccountDeletedMessage =  "Errors were detected in script, $username will not be removed from AD."
						Write-Warning $user.AccountDeletedMessage
						$error.exception.message|%{Write-Warning "Error: ${username}: $($_)"}
						$error.Clear()
					} 
				}
			}#End Delete Account Switch
			#endregion Delete Account
			
			$Output = @"
----------- Copy into ticket --------------------------------
Termination of $($user.'display name')
AD Account: $($user.logon)
$($user.homespacemessage)
$($user.MailboxArchiveMessage)
$($user.MailboxDisableMessage)
$($user.AccountDeletedMessage)
$(if($user.O365){"Account Uses Office 365."})

"@
			Write-Output $Output
			$Output | Out-File -FilePath $UserDir\log-$(get-date -f MM-dd-yy.HHmm).txt -Append
			
		}# end foreach user
		
	}#process end
	END {
		$SelectedAccounts|Out-File -Append -FilePath $ArchiveRoot\log-$(get-date -f MM-dd-yy.HHmm).txt
		$SelectedAccounts|Out-GridView
		Get-Job -State Completed|Remove-Job
		$SelectedAccounts
	}
}#function end

Start-ProcessTerminations
""
If (!($psISE)){"Press any key to continue...";[void][System.Console]::ReadKey($true)}