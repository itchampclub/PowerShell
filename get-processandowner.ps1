function get-processandowner ($computer)
{
    $owners=@{}
    gwmi win32_process -ComputerName $computer | % {$owners[$_.handle] = $_.getowner().user}
    get-process -ComputerName $computer | select *,@{l="Owner";e={$owners[$_.id.tostring()]}}
}