## Precreated Demo Profile ##
Write-Host -ForegroundColor Cyan "Profile loaded at $(Get-Date)."
New-Item alias:npp -Value "C:\Program Files (x86)\Notepad++\notepad++.exe" | Out-Null
$Host.UI.RawUI.WindowTitle = "PS -- $env:computername -- $env:userdomain\$env:username"

<#

function global:prompt {
    "I♥PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
}

#>

