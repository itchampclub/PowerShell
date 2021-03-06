﻿function Get-AppleDeviceLocation
{ 
<#
.Synopsis
    Gets device locations from iCloud.

.Description
    Get-AppleDeviceLocation gets a list of devices from an iCloud account and returns locations where available.

.Parameter Credential
    Apple ID and password for iCLoud account.
    Must be a PSCreditial.

.Parameter FamilyToo
    If specified, will include family member devices, if available.

.Parameter AllDevices
    If specified, will include devices that do not have a location.

.Parameter DontWaitForLocationFix
    If specified, will not wait for a device to report a location.

.Example
Get-AppleDeviceLocation -Credential $iCloudCred 


DeviceName        : Tommy Becker’s iPad
DeviceDisplayName : iPad Air 2
BatteryLevel      : 0.0
BatteryStatus     : Unknown
Longitude         : REDACTED
Latitude          : REDACTED

.Example
Get-AppleDeviceLocation -Credential $iCloudCred -AllDevices

DeviceName          DeviceDisplayName
----------          -----------------
Tommy’s MacBook Pro MacBook Pro 15"  
Tommy Becker’s iPad iPad Air 2      

.Example
Get-AppleDeviceLocation -Credential $iCloudCred -AllDevices -FamilyToo

DeviceName          DeviceDisplayName
----------          -----------------
Tommy’s MacBook Pro MacBook Pro 15"  
Tommy Becker’s iPad iPad Air 2       
Ronni’s iPod        iPod             
Ronni’s iPod        iPod             
Ronnis MacBook Air  MacBook Air 13"  
Ronni's iPad        iPad mini        
iPhone              iPhone 5s        
Aryana's iPhone     iPhone 4s  

.Outputs
    [PSCustomObject]
    
.Link
    https://github.com/mockmyberet/PowerShell/blob/master/Get-AppleDeviceLocation
#>

    [cmdletbinding()] 
    param( 
          [Parameter(Mandatory=$true,
                     HelpMessage="You need to pass your iCloud credentials to this parameter.")] 
          [System.Management.Automation.PSCredential] $Credential, 
          [switch] $FamilyToo,
          [switch] $AllDevices,
          [switch] $DontWaitForLocationFix
         ) 
    if($PSVersionTable.PSVersion.Major -lt 3){Write-Error "This function requires Powershell 3 or above." -ea Stop;break}

    $clientId = [guid]::NewGuid() 

    $LoginUri = "https://p07-setup.icloud.com/setup/ws/1/login?&clientId=$clientId" 

    $PayloadHash = @{ 
                        apple_id = $Credential.UserName 
                        extended_login = $false 
                        password = $Credential.GetNetworkCredential().Password 
                    } 
    $PayloadJsonObj = $PayloadHash | ConvertTo-Json 
    $Header = @{ 
                'Origin' = 'https://www.icloud.com' 
                'Referer' = 'https://www.icloud.com' 
               } 
    try
    {
    Write-Verbose "Attempting to authenticate to iCloud servers."
    $LoginData = Invoke-RestMethod -Uri $LoginUri -Body $PayloadJsonObj -Headers $Header -Method Post -SessionVariable iCloudSession -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Opera) -ErrorAction Stop
    }
    catch
    {
    Write-Warning "iCloud login failed, make sure you used your Apple ID and password."
    break
    }
    Write-Verbose "Authentication complete for $($LoginData.dsInfo.fullName)."
    Write-Debug $LoginData

    $FindMyiPhoneURI = "https://p07-fmipweb.icloud.com/fmipservice/client/web/initClient?clientId=$clientId&dsid=$($LoginData.dsInfo.dsid)" 
    
    $LocationPayload = @{ 
                           clientContext = @{ 
                                apiVersion = '3.0' 
                                appName = 'iCloud Find (Web)' 
                                appVersion = '2.0'
                                fmly = $FamilyToo.IsPresent
                                inactiveTime = '2255' 
                                timezone = 'US/Central' 
                            } 
                        } 

    $LocationPayloadJsonObj = $LocationPayload | ConvertTo-Json 
    
    $WaitingForLocationFix = $true 
    
    while ($WaitingForLocationFix) { 
        try
        {
        Write-Verbose "Attempting to find devices."
        $LocationPostResults = Invoke-RestMethod -Uri $FindMyiPhoneURI -Body $LocationPayloadJsonObj -Method Post -WebSession $iCloudSession -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Opera) 
        }
        catch
        {
        Write-Warning "Web services request failed. Time to debug."
        break
        } 
        Write-Verbose "Found $($LocationPostResults.content.count) total devices."
        Write-Debug $LocationPostResults
        
        foreach ($iOSDevice in $LocationPostResults.content) { 
            if ($iOSDevice.location) { 
                [PSCustomObject] @{ 
                                    DeviceName = $iOSDevice.name 
                                    DeviceDisplayName = $iOSDevice.deviceDisplayName 
                                    BatteryLevel = $iOSDevice.batteryLevel 
                                    BatteryStatus = $iOSDevice.batteryStatus 
                                    Longitude = $iOSDevice.location.longitude 
                                    Latitude = $iOSDevice.location.latitude 
                                  } 
                Write-Debug $iOSDevice 

                $WaitingForLocationFix = $false 
            } 
            elseif ($AllDevices.IsPresent)
            {
            [PSCustomObject] @{ 
                                DeviceName = $iOSDevice.name 
                                DeviceDisplayName = $iOSDevice.deviceDisplayName
                                } 
            Write-Debug $iOSDevice 
            $WaitingForLocationFix = $false 
            }
        } 


        if (!$DontWaitForLocationFix.IsPresent -and $WaitingForLocationFix) { 
            Write-Warning 'Waiting for devices to be located...' 
            Start-Sleep -Seconds 5 
        } 
        else { 
            $WaitingForLocationFix = $false 
        } 
    } 
} 