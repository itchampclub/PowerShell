function Get-DellWarrantyInfo
{
[CmdletBinding()]
param(
[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ServiceTag
)
begin
{
$service = New-WebServiceProxy -Uri http://143.166.84.118/services/assetservice.asmx?WSDL
}
process
{
foreach ($ThisTag in $ServiceTag)
{
    $guid = [guid]::NewGuid()
    $infos = $service.GetAssetInformation($guid,'check_warranty.ps1',$ThisTag)
    foreach($info in $infos)
    {
        foreach($entitlement in $info.Entitlements)
        {
            $entitlement|select @{Name="ServiceTag";Expression={$info.AssetHeaderData.ServiceTag}},
            @{Name="SystemID";Expression={$info.AssetHeaderData.SystemID}},
            @{Name="Buid";Expression={$info.AssetHeaderData.Buid}},
            @{Name="Region";Expression={$info.AssetHeaderData.Region}},
            @{Name="SystemType";Expression={$info.AssetHeaderData.SystemType}},
            @{Name="SystemModel";Expression={$info.AssetHeaderData.SystemModel}},
            @{Name="SystemShipDate";Expression={$info.AssetHeaderData.SystemShipDate}},
            *
        }#foreach entitlement
    }#foreach info
}#foreach thistag
}
end
{
}

}#End Function