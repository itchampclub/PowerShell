switch (([version](Get-WmiObject Win32_OperatingSystem).version).major)
{
    5 {"pre-vista"}
    6 {"post-vista"}
    Default {throw{"Danger, Will Robinson!"}}
}