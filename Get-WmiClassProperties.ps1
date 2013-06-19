#Get-WmiClassMethods.ps1
# -----------------------------------------------------------------------------
# Script: Get-WmiClassProperties.ps1
# Author: ed wilson, msft
# Date: 03/08/2011 12:46:15
# Keywords: Scripting Techniques, WMI
# comments: Gets dynamic WMI classes that have methods marked with the implemented
# qualifier
# HSG-3-11-11
# -----------------------------------------------------------------------------
function New-Underline
{
<#
.Synopsis
 Creates an underline the length of the input string
.Example
 New-Underline -strIN "Hello world"
.Example
 New-Underline -strIn "Morgen welt" -char "-" -sColor "blue" -uColor "yellow"
.Example
 "this is a string" | New-Underline
.Notes
 NAME:
 AUTHOR: Ed Wilson
 LASTEDIT: 5/20/2009
 KEYWORDS:
.Link
 Http://www.ScriptingGuys.com
#>
[CmdletBinding()]
param(
      [Parameter(Mandatory = $true,Position = 0,valueFromPipeline=$true)]
      [string]
      $strIN,
      [string]
      $char = "=",
      [string]
      $sColor = "Green",
      [string]
      $uColor = "darkGreen",
      [switch]
      $pipe
 ) #end param
 $strLine= $char * $strIn.length
 if(-not $pipe)
  {
   Write-Host -ForegroundColor $sColor $strIN
   Write-Host -ForegroundColor $uColor $strLine
  }
  Else
  {
  $strIn
  $strLine
  }
} #end new-underline function
 
Function Get-WmiClassProperties
{
 Param(
   [string]$namespace = "root\cimv2",
   [string]$computer = "."
)
 $abstract = $false
 $property = $null
 $classes = Get-WmiObject -List -Namespace $namespace
 Foreach($class in $classes)
 {
  Foreach($q in $class.Qualifiers)
   { if ($q.name -eq 'Abstract') {$abstract = $true} }
  If(!$abstract)
    {
     Foreach($p in $class.Properties)
      {
       Foreach($q in $p.qualifiers)
        {
         if($q.name -match "write")
          {
            $property += $p.name + "`r`n"
          } #end if name
        } #end foreach q
      } #end foreach p
      if($property) {New-Underline $class.name}
      $property
    } #end if not abstract
  $abstract = $false
  $property = $null
 } #end foreach class
} #end function Get-WmiClassProperties
 
# *** Entry Point to Script ***
Get-WmiClassProperties