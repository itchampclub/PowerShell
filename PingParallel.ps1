workflow PingParallel {
  param(

    [string[]]$Computers

  )
  foreach -parallel ($computer in $computers) {
    $strName = $computer.ToUpper().Trim().ToString()
    $PingResult = Test-Connection -ComputerName $strName -Count 1 -ErrorAction SilentlyContinue
    inlinescript{
            if ($using:PingResult.ResponseTime -eq $null){
                Write-Output "$($using:strName) is not responding."
            } else {
                Write-Output "$($using:strName)'s IP is $($PingResult.IPV4Address) and responds in $($PingResult.ResponseTime) ms."
            }
}
}
}
