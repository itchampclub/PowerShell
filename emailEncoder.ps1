function Encode-Email{
param(
$email = "tommy.becker@gmail.com"
)
Write-Host -NoNewline "[string](0..$($email.Length-1)|%{[char][int](46+("""
[int[]][char[]]$email | foreach{Write-Host -NoNewline "$($_-46)".Replace(0,"00").Substring(0,2)}
Write-Host -NoNewline """).substring((`$_*2),2))})-replace "" """
}
