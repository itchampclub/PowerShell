$excel = New-Object -com excel.application
$excel.Visible = $true
$excel.DisplayAlerts = $false
$workbook = $excel.Workbooks.Add()
#$S1 = $workbook.Sheets | ? {$_.Name -eq "Sheet1"}
#$S2 = $workbook.Sheets | ? {$_.Name -eq "Sheet2"}
#$S3 = $workbook.Sheets | ? {$_.Name -eq "Sheet3"}
#$S2.Delete()
#$S3.Delete()
$worksheets = $workbook.worksheets
$worksheets.Item(2).delete()
$worksheets.Item(2).delete()
$S1 = $worksheets.Item(1)
$S1.Name = "test"
$workbook.author = "Tommy Becker" 
$workbook.title = "Spreadsheet Tester" 
$workbook.subject = "Demonstrating PowerShell with Excel" 
$S1.range("A1:A1").cells="Cell a1" 
$S1.range("A2:A2").cells="A2" 
$S1.range("b1:b1").cells="Cell B1" 
$S1.range("b2:b2").cells="b2" 
$S1.range("E1:E2").cells="Widgets" 
$S1.range("E2:E2").cells=2 
$S1.range("E3:E3").cells=2 
$S1.range("E4:E4").cells=38 
$S1.range("D5:D5").cells="Total" 
$S1.range("E5:E5").cells.formula = "=sum(e2,E4)" 
$S1.Cells.Item(1,1).value2 = "hello test"
$S1.SaveAs("excel test.xlsx")
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
Remove-Variable excel
