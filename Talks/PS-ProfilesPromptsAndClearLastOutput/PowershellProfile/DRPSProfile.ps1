######################
##   Safe for ISE   ##
######################

cd C:\

##Clipboard shortcuts
function Get-ClipboardMinusOne {
    $Clipboard = Get-Clipboard
    $Clipboard = $Clipboard[0..($Clipboard.count-2)]
    $Clipboard
}
Set-Alias -Name gcc -Value Get-ClipboardMinusOne

function Check-Transcribing {
    $host.ui.gettype().GetMember("IsTranscribing","NonPublic,Instance").GetMethod.Invoke($host.ui, $null)
}

function Set-ClipboardMinusOne {
    Get-ClipboardMinusOne | Set-Clipboard
    Write-Host -ForegroundColor Green "Last clipboard item removed."
}
Set-Alias -Name scc -Value Set-ClipboardMinusOne

Remove-Item alias:gc -Force
Set-Alias -Name gc -Value Get-Clipboard


#SCCM shortcuts!
set-alias -name rcd -value Remove-CMDevice

function Import-CMModules {
	Import-Module "$env:SMS_ADMIN_UI_PATH\..\configurationmanager.psd1"
}
set-alias -name cmm -value Import-CMModules


#various tiny functions and aliases
function Convert-ToBinary ([string]$Number) {[Convert]::ToString($Number,2)}
Set-Alias -Name bin -Value Convert-ToBinary

function Sign-DRPSScript ($Path) {
	Set-AuthenticodeSignature -FilePath $Path -Certificate @(Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert)[0]
}
Set-Alias -name sign -Value Sign-DRPSScript

function Check-Admin {
	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Get-LAPSPasswordADSI([string[]]$ComputerName) {
    foreach ($Computer in $ComputerName) {
        $Search = [adsisearcher]"(name=$Computer)"
        $Search.FindOne().properties.'ms-mcs-admpwd'
    }
}

New-Item alias:npp -Value "C:\Program Files (x86)\Notepad++\notepad++.exe"

Remove-Item alias:man
Function man{param($Command)Get-Help $Command -Full | more}


function Out-Voice {
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline)]
		[string]$Text="No speech input given!",
		[Parameter(ValueFromPipeline)]
		[int]$Rate=3
	)
	Add-Type -AssemblyName System.Speech
	$SpeechCaller = New-Object System.Speech.Synthesis.SpeechSynthesizer
	$SpeechCaller.Rate = $Rate
	$SpeechCaller.Speak($Text)
}


#win title magic
$host.ui.rawui.windowtitle = "$(if ($psise){"ISE "})$(if (Check-Admin) {"Administrator: "} else {"Non-elevated: "})$((Get-NetIPAddress) -match "^10.*" | select -ExpandProperty ipaddress) -- $env:computername -- $env:userdomain\$env:username"


function Edit-Profile {
	$ThisFile = $PSScriptRoot
	npp $ThisFile
}




################################
## Not Safe for ISE or VSCode ##
################################

$SafeConsoleNotISEOrVSCode = if ($host.name -eq "ConsoleHost") {$true}

if ($SafeConsoleNotISEOrVSCode) {
	#pwd cleanup, hide those cookies
	if ($pwd.path -eq "C:\Users\david.richmond\Desktop\Cookies\AHK\ahkl") {cd C:\}

<#
	#window resizing!
	$buffer = $host.ui.rawui.buffersize
	$buffer.width = 110
	$buffer.height = 9999
	$host.ui.rawui.buffersize = $buffer

	$window = $host.ui.rawui.windowsize
	$window.width = 110
	$window.height = 50
	$host.ui.rawui.windowsize = $window
#>

	#clear last output handling
	$global:outputlinecountarray = New-Object System.Collections.ArrayList
	$global:lastoutputcalclines=0

	function Clear-HostLastOutput {
		Param (
			[Parameter(Position=1)]
			[int32]$Count=$global:lastoutputcalclines+1,
			[Parameter(Position=2)]
			[switch]$test=$false
		)

		$CurrentLine  = $Host.UI.RawUI.CursorPosition.Y
		$ConsoleWidth = $Host.UI.RawUI.BufferSize.Width

		$i = 1
		for ($i; $i -le $Count; $i++) {
			[Console]::SetCursorPosition(0,($CurrentLine - $i))
			[Console]::Write("{0,-$ConsoleWidth}" -f " ")
		}

		[Console]::SetCursorPosition(0,($CurrentLine - $Count))
		if ($test) {Write-Host "count = $count`nlast output count: $global:lastoutputcalclines`narray:$outputlinecountarray"}
		$outputlinecountarray.removeat($outputlinecountarray.count-1)
		
		#this moves the output down the screen so we're not left with one line way up top looking like it's all that's there
		#that it does this appears to be "convenient" and not necessarily "intended". but who even knows anymore.
		$host.ui.rawui.windowposition = @{x=0;y=0} 
		
	}
	set-alias -name clo -value Clear-HostLastOutput
	function Clear-HostLastLine {Clear-HostLastOutput 1}
	set-alias -name cll -value "Clear-HostLastLine"
}


######################
####### Prompt #######
######################

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
	
	if (Check-Admin) {
        $Symbol = '#'
		$SymbolColor = "Red"
    } Else {
        $Symbol = '$'
		$SymbolColor = "Green"
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
    Write-Host "$currentDirectory$arrows"
}
Clear-Host
Write-Host "$((Get-NetIPAddress) -match "10.*" | select -ExpandProperty ipaddress) -- $env:computername"
(Get-Date | Out-String).Trim()
