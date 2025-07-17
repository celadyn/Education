Write-Host -ForegroundColor Magenta "No F5ing the demo!"
break
Read-Host -Prompt "F5 ruination prevention just in case we break break."

############

cd c:\repo


# Starting off - just in case!

Set-ExecutionPolicy -Scope LocalMachine Bypass



# Check the current profile
$profile

Test-Path $profile


# :( :(
# Oh well, just make it.

New-Item $profile


# :( :(
# Pourquoi?? 

start (Split-Path $profile -Parent)

start (Split-Path (Split-Path $profile -Parent) -Parent)



# Making directories manually = PITA.

New-Item $profile -Force | Out-Null

Test-Path $profile

# Time to play in the new profile!

Set-Content -Path $profile -Value '## Profile ##'
Get-Content $profile

Add-Content -Path $profile -Value 'Write-Host -ForegroundColor Cyan "Profile loaded at $(Get-Date)."'
Get-Content $profile

Add-Content -Path $profile -Value 'New-Item alias:npp -Value "C:\Program Files (x86)\Notepad++\notepad++.exe"'
Get-Content $profile

Add-Content -Path $profile -value '$Host.UI.RawUI.WindowTitle = "PS -- $env:computername -- $env:userdomain\$env:username"'
Get-Content $profile

psedit $profile

## Time to test loading! 

###############################################

## ...okay, that's annoying. Time to null it out.

# Static is great but we live in a dynamic world.

$UniversalProfilePath = "C:\repo\PowershellProfile\DRPSProfileDemo.ps1"

$UniversalProfileContent = ". $UniversalProfilePath"

Get-Content $profile

Set-Content -Path $profile -Value $UniversalProfileContent

Get-Content $profile

Start-Process powershell.exe


################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################
################

# But $profile isn't just an environmental variable with a single string...

$profile | select *

$profile | Get-Member -Type NoteProperty


# Even though a weird object, we can steal the values of each profile path with this:
$ProfilePaths = $profile.psobject.Properties | ? {$_.membertype -eq "NoteProperty"} | Select-Object -ExpandProperty value

$ProfilePaths

# Annoyingly, the default interactive host profile doesn't show up in this list, so let's go find out what it is...

start powershell.exe

$ProfilePaths += "C:\Users\dsr\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"


# SUPER annoyingly, pwsh is also left out of the list!

start pwsh.exe

$ProfilePaths += "C:\Users\dsr\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"


# The final list of (almost all) profiles that'll actually be used:
$ProfilePaths


$ProfilePaths | Where-Object {$_ -notmatch "System32"} | ForEach-Object {
    Write-Host -ForegroundColor Yellow "Processing profile $_"
    
    try {
        $test = Test-Path $_
        if ($test -eq $false) {
            New-Item $_ -Force | Out-Null
            Set-Content -Path $_ -Value $UniversalProfileContent -Force | Out-Null
            Write-Host -ForegroundColor Green "Profile created at $_"
        }
        else {
            Write-Host -ForegroundColor Red "Profile already exists at $_"
        }
    }
    catch {Write-Warning "Error processing profile - $_.exception.message"}
}

# testing the result of what we've done

Get-Content $ProfilePaths[2]

################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################
################ ################


########### Now to talk about.... prompts!

# For some annoying redundancy:

prompt

# prompt is just a function:

Get-Item function:prompt

# ...and actually has content:

(Get-Item function:prompt).Definition


# ...and can be remade at will with the important bits:

function prompt {
    "I♥PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "    
}

(Get-Item function:prompt).Definition


# Let's just jump into a ton of stuff.

. .\DemoPrompt.ps1


################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################
################ ################ ################


# From here on out it's the wild west............


$UniversalProfilePath = "C:\repo\PowershellProfile\DRPSProfile.ps1"

$UniversalProfileContent = ". $UniversalProfilePath"

#### Insert acquisition of profile from github or whatever here ####


$ProfilePaths = $profile.psobject.Properties | ? {$_.membertype -eq "NoteProperty"} | Select-Object -ExpandProperty value



$ProfilePaths | Where-Object {$_ -notmatch "System32"} | ForEach-Object {
    Write-Host -ForegroundColor Yellow "Processing profile $_"
    
    try {
        $test = $false
        if ($test -eq $false) {
            New-Item $_ -Force | Out-Null
            Set-Content -LiteralPath $_ -Value $UniversalProfileContent -Force | Out-Null
            Write-Host -ForegroundColor Green "Profile created at $_"
        }
        else {
            Write-Host -ForegroundColor Red "Profile already exists at $_"
        }
    }
    catch {Write-Warning "Error processing profile - $_.exception.message"}
}