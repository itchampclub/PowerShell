$ParserTokens = $null
$ParserErrors = $null
$AST = [System.Management.Automation.Language.Parser]::ParseFile("h:\github\powershell\Get-DellWarrantyInfo.ps1",[ref]$ParserTokens,[ref]$ParserErrors)
