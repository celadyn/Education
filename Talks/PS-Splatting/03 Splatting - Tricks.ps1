### Splatting 101
### 02 - Splatting Tricks

Set-Location $PSScriptRoot
& {break} # no F5ing!

# Intellisense intelligence!
$HostSplat = @{
    ForegroundColor = "DarkCyan"
    BackgroundColor = "Magenta"
    
    # -- #
}


Write-Host @HostSplat






#################
# Great for randomly ruining your day!


$InvokeRestMethodSplat = @{
    Uri                = "http://ip-api.com/json/?fields=51462"
    SkipHttpErrorCheck = $true
    SkipCertificateCheck = $true
    Headers           = @{
        "User-Agent" = "PowerShell-Training-Splatting"
        "Accept"     = "application/json"
    }
    Verbose = $true
}

Invoke-RestMethod @InvokeRestMethodSplat 





##################
# Array of splats? Do a quick inspection:

# no bueno
,$InvokeRestMethodSplat * 10 | Out-GridView

# muy bueno
,$InvokeRestMethodSplat * 10 | Foreach-Object {[pscustomobject]$_} | Out-GridView






#################
# Useful for whatif

function Invoke-ComplicatedAction {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$Name
        ,
        $AuthorizationCode = (New-Guid).Guid * 10 -replace "-"
    )

    $CrazyStuffSplat = @{
        Name = $Name
        Location = Get-Location
        Action = "Complicated things"
        Priority = if ([datetime]::DaysInMonth([datetime]::Now.Year, [datetime]::Now.Month) -eq 31 ) {"Maximum"} else {"Medium"}
        AuthToken = $AuthorizationCode
        Force = $true
    }

    if ($PSCmdlet.ShouldProcess("Complicated things for $Name")) {
        Invoke-ComplicatedThings @CrazyStuffSplat -Verbose
    } else {
        Write-Warning "Whatiffed! Not doing anything."
        #$CrazyStuffSplat.AuthToken = $CrazyStuffSplat.AuthToken.Substring(0,5) + "...[redacted]..."
        $CrazyStuffSplat | Format-List | Out-String | Write-Warning
    }
}

Invoke-ComplicatedAction -Name "Delete All Data" -WhatIf



#################
# Even BETTER for hypotheticals and staging

function Invoke-DangerousAction {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]$Name
    )

    begin {}

    process {
        foreach ($ObjectName in $Name) {
            $ExecuteSplat = @{
                Name             = $Name
                ObjectID         = Get-Location
                RelatedResources = 1..10
                Action           = "Complicated things"
                Priority         = if ([datetime]::DaysInMonth([datetime]::Now.Year, [datetime]::Now.Month) -eq 31 ) { "Maximum" } else { "Medium" }
                AuthToken        = (New-Guid).Guid
                Force            = $true
                DisregardPhysics = $true
            }

            if ($PSCmdlet.ShouldProcess("Complicated things for $Name")) {

                Invoke-ComplicatedThings @CrazyStuffSplat -Verbose -ErrorAction Stop
                $ExecuteSplat.Add("Executed",$true)
                $ExecuteSplat.Add("Success",$true)

            } else {
                Write-Warning "Whatiffed! Emitting hypothetical splat."
                $ExecuteSplat.AuthToken = $CrazyStuffSplat.AuthToken.Substring(0,5) + "...[redacted]..."
                $ExecuteSplat.Add("Executed",$false)
                $ExecuteSplat.Add("Success",$false)
            }
            
            $ExecuteSplat
        }#foreach
    }#process
}

Invoke-DangerousAction -Name "Delete All Data" -WhatIf


# next step - one cmdlet to generate splats, another to execute


# the sky is the limit!