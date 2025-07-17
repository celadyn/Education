$ProfilePaths = $profile.psobject.Properties | ? {$_.membertype -eq "NoteProperty"} | Select-Object -ExpandProperty value
$ProfilePaths += "C:\Users\dsr\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ProfilePaths += "C:\Users\dsr\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"


$ProfilePaths | ForEach-Object {
    Write-Host -ForegroundColor Yellow "Processing profile $_"
    try {
        Remove-Item $_ -ErrorAction Stop
        Write-Host -ForegroundColor Green "Deleted profile at $_"
    }
    catch {Write-Warning $_.exception.message}
}

Remove-Item "C:\Users\dsr\Documents\WindowsPowerShell" -Recurse
Remove-Item "C:\Users\dsr\Documents\PowerShell\" -Recurse

function prompt {
    "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "    
}

$ProfilePaths = $null

Read-Host -prompt "Done!"
Clear-Host