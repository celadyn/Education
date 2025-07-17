function global:prompt {
    $runTime = '[0s]' 
    $LastCmd = get-history -count 1
    if($LastCmd)
    {
        $executionTime = ($LastCmd.EndExecutionTime - $LastCmd.StartExecutionTime)
        if ($executionTime.TotalSeconds -ge 60)
        {
            $runTime = '[{0:N2}m]' -f $executionTime.TotalMinutes
        }
        elseif ($executionTime.TotalSeconds -lt 1)
        {
            $runTime = '[{0:N2}ms]' -f $executionTime.TotalMilliseconds
        }
        else
        {
            $runTime = '[{0:N2}s]' -f $executionTime.TotalSeconds
        }
    }
		
    $arrows = '>'
    if ($NestedPromptLevel -gt 0) {$arrows = $arrows * $NestedPromptLevel}

    $currentDirectory = Get-Location

	if ($SafeConsoleNotISEOrVSCode) {
		if ($outputlinecountarray -contains "0" -or ($outputlinecountarray[-1]-$outputlinecountarray[-2]) -lt 0) {$outputlinecountarray.Clear();$outputlinecountarray.Add($host.ui.rawui.cursorposition.y) | Out-Null}
		if ($outputlinecountarray[-1] -ne $host.ui.rawui.cursorposition.y) {$outputlinecountarray.Add($host.ui.rawui.cursorposition.y) | Out-Null}
		
		$global:lastoutputcalclines = ($outputlinecountarray[-1]-$outputlinecountarray[-2])
		#$global:previouspromptcalclines = $global:currentpromptcalclines
		#$global:currentpromptcalclines = $host.ui.rawui.cursorposition.y
		#$global:lastoutputcalclines = $global:currentpromptcalclines - $global:previouspromptcalclines

		Write-Host "L:$lastoutputcalclines@$($outputlinecountarray[-1]) " -ForegroundColor Magenta -NoNewline
	}
    Write-Host "$runTime @ $(Get-Date) " -ForegroundColor Yellow -NoNewline
    Write-Host "PS$Symbol " -ForegroundColor $SymbolColor -NoNewline
    Write-Host "$currentDirectory$arrows" -NoNewline
    ' '
    Get-Process
}
