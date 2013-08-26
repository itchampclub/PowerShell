
<!-- saved from url=(0131)http://powershell.com/cs/cfs-filesystemfile.ashx/__key/CommunityServer.Components.PostAttachments/00.00.00.96.00/network-packV3.ps1 -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=windows-1252"><style type="text/css"></style></head><body style="zoom: 1;" class=" hasGoogleVoiceExt"><pre style="word-wrap: break-word; white-space: pre-wrap;">function Get-IPAddress {
	# created by Dr. Tobias Weltner, MVP PowerShell

	param(
		[switch]
		$first,
		[Parameter(ParameterSetName='IPV4')]
		[switch]
		$IPv4,
		[Parameter(ParameterSetName='IPV4')]
		[switch]
		$IPv6
	)
	$ip = @(Get-WmiObject -Filter 'IPEnabled=true' Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty IPAddress)
	if ($IPv4) { $ip = $ip | Where-Object { $_ -like '*.*' }}
	if ($IPv6) { $ip = $ip | Where-Object { $_ -like '*:*' }}

	if ($ip.Count -gt 1 -and $first) {
		$ip[0]
	} else {
		$ip
	}
}


function New-IPRange {
	# created by Dr. Tobias Weltner, MVP PowerShell

	[CmdletBinding(DefaultParameterSetName='Automatic')]
	param(
		[Parameter(ParameterSetName='Manual')]
		[String]
		$start, 
		[Parameter(ParameterSetName='Manual')]
		[String]
		$end,
		[Parameter(ParameterSetName='Automatic')]
		[switch]
		$first
	)


	function Get-IPRange($start, $end) {
		$ip1 = ([System.Net.IPAddress]$start).GetAddressBytes()
		[Array]::Reverse($ip1)
		$ip1 = ([System.Net.IPAddress]($ip1 -join '.')).Address
	
		$ip2 = ([System.Net.IPAddress]$end).GetAddressBytes()
		[Array]::Reverse($ip2)
		$ip2 = ([System.Net.IPAddress]($ip2 -join '.')).Address
	
		for ($x = $ip1; $x -le $ip2; $x++) {
			$ip = ([System.Net.IPAddress]$x).GetAddressBytes()
			[Array]::Reverse($ip)
			$ip -join '.'
		}
	
	}
	
	if ($PSCmdlet.ParameterSetName -eq 'Automatic') {
		@(Get-IPAddress -first:$first -IPv4) |
		ForEach-Object {
			$temp = ([System.Net.IPAddress]$_).GetAddressBytes()
			$temp[3] = 1
			[System.Net.IPAddress]$start = $temp -join '.'
			$temp[3] = 255
			[System.Net.IPAddress]$end = $temp -join '.'
			Get-IPRange $start $end		
		}
	} else {
		Get-IPRange $start $end
	}	
}

function Test-Online {
	# created by Dr. Tobias Weltner, MVP PowerShell

	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[String]
		$computername,
		[Int32]
		$throttleLimit = 300
	)

	begin { $list = New-Object System.Collections.ArrayList }
	process { 
		[void]$list.Add($computername)
	}
	end {
		&amp; { 
			do {
			$number = [Math]::Min($list.Count, $throttleLimit)
			$chunk = $list.GetRange(0, $number)
			
			$job = Test-Connection $chunk �Count 1 �asJob
			$job | Wait-Job | Receive-Job | Where-Object { $_.StatusCode �eq 0 } | Select-Object �expandProperty Address 
			Remove-Job $job
			$list.RemoveRange(0, $number)
		} while ($list.Count -gt 0) 
		} | Sort-Object { [System.Version]$_ }
	}

}

function Get-HostName {
	# created by Dr. Tobias Weltner, MVP PowerShell

	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[String[]]
		$IPAddress
	)

	process {
		$IPAddress | Foreach-Object {
			$ip = $_
			try {
				[System.Net.DNS]::GetHostByAddress($ip)
			} catch { 
				Write-Warning �IP $ip did not return DNS information�
			}
		}
	}
}


New-IPRange | Test-Online | Get-HostName</pre><input type="text" id="webshortcutscurcmd" style="display: none;"></body></html>