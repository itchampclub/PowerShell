param(
  [UInt32] $Length=8,
  [Switch] $LowerCase=$TRUE,
  [Switch] $UpperCase=$TRUE,
  [Switch] $Numbers=$TRUE,
  [Switch] $Symbols=$FALSE,
  [Uint32] $Count=20
)

if ($Length -lt 4) {
  throw "-Length must specify a value greater than 3"
}

if (-not ($LowerCase -or $UpperCase -or $Numbers -or $Symbols)) {
  throw "You must specify one of: -LowerCase -UpperCase -Numbers -Symbols"
}


$CHARSET_LOWER = 1
$CHARSET_UPPER = 2
$CHARSET_NUMBER = 4
$CHARSET_SYMBOL = 8

$charsLower = 97..122 | foreach-object { [Char] $_ }
$charsUpper = 65..90 | foreach-object { [Char] $_ }
$charsNumber = 48..57 | foreach-object { [Char] $_ }
$charsSymbol = 35,36,42,43,44,45,46,47,58,59,61,63,64,
  91,92,93,95,123,125,126 | foreach-object { [Char] $_ }

$charList = @()
$charSets = 0
if ($LowerCase) {
  $charList += $charsLower
  $charSets = $charSets -bor $CHARSET_LOWER
}
if ($UpperCase) {
  $charList += $charsUpper
  $charSets = $charSets -bor $CHARSET_UPPER
}
if ($Numbers) {
  $charList += $charsNumber
  $charSets = $charSets -bor $CHARSET_NUMBER
}
if ($Symbols) {
  $charList += $charsSymbol
  $charSets = $charSets -bor $CHARSET_SYMBOL
}

function test-stringcontents([String] $test, [Char[]] $chars) {
  foreach ($char in $test.ToCharArray()) {
    if ($chars -ccontains $char) { return $TRUE }
  }
  return $FALSE
}
$tempFile = [io.path]::GetTempFileName()
1..$Count | foreach-object {
  do {
    # No character classes matched yet.
    $flags = 0
    $output = ""
    # Create output string containing random characters.
    1..$Length | foreach-object {
      $output += $charList[(get-random -maximum $charList.Length)]
    }
    # Check if character classes match.
    if ($LowerCase) {
      if (test-stringcontents $output $charsLower) {
        $flags = $flags -bor $CHARSET_LOWER
      }
    }
    if ($UpperCase) {
      if (test-stringcontents $output $charsUpper) {
        $flags = $flags -bor $CHARSET_UPPER
      }
    }
    if ($Numbers) {
      if (test-stringcontents $output $charsNumber) {
        $flags = $flags -bor $CHARSET_NUMBER
      }
    }
    if ($Symbols) {
      if (test-stringcontents $output $charsSymbol) {
        $flags = $flags -bor $CHARSET_SYMBOL
      }
    }
  }
  until ($flags -eq $charSets)
 $output | Out-File $tempFile -Append
}


Get-Content $tempFile
notepad $tempFile
Start-Sleep -s 10
Remove-Item $tempFile
