### Splatting 101
### 02 Splatting - More

Set-Location $PSScriptRoot
& {break} # no F5ing!

#########################################################################


# Not just for creating - reuse them, and modify them!

$ModuleSplat = [ordered]@{
    Name               = "Az.Accounts"
    Repository         = "PSGallery"
    SkipPublisherCheck = $true
    Verbose            = $true
    Whatif             = $true
}

Install-Module @ModuleSplat

$ModuleSplat.Remove("SkipPublisherCheck")
$ModuleSplat.Remove("Repository")
Update-Module @ModuleSplat

# conditionally add parameters
if ($PSVersionTable.PSVersion -ge [version]"7.0") {
    $ModuleSplat.Add("Scope","AllUsers")
}
Update-Module @InstallModuleSplat


# More complex use case with reuse and conditionals!

function Invoke-ModuleRequirement {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [string[]]$Name
        ,
        [string]$Repository
        ,
        [Parameter()]
        [ValidateSet("AllUsers","CurrentUser")]
        [string]$Scope = "AllUsers"
        ,
        [switch]$SuperVerbose
    )

    begin {
        # initialize splat bases

        $InstallModuleBaseSplat = @{
            Name = $null
            Scope = $Scope
            SkipPublisherCheck = $true
            Verbose = [bool]$SuperVerbose
        }

        $UpdateModuleBaseSplat = @{
            Name = $null
            Verbose = [bool]$SuperVerbose
        }

        $FindModuleBaseSplat = @{
            Name = $null
            Verbose = [bool]$SuperVerbose
        }

        if ($PSVersionTable.PSVersion -match "^7") {
            $UpdateModuleBaseSplat.Add("Scope",$Scope)
        }

        if ($Repository) {
            $InstallModuleBaseSplat.Add("Repository",$Repository)
            $FindModuleBaseSplat.Add("Repository",$Repository)
        }
    }

    process {
        foreach ($ModuleName in $Name) {
            $InstallModuleSplat.Name = $ModuleName
            $UpdateModuleSplat.Name = $ModuleName
            $FindModuleSplat.Name = $ModuleName

            if (-not (Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue)) {
                $ModuleLookup = Find-Module @FindModuleBaseSplat
                if ($ModuleLookup -and $ModuleLookup.Count -gt 0) {
                    Install-Module @InstallModuleSplat
                } else {
                    Write-Warning "Module '$ModuleName' not found in repository '$Repository'."
                }
            } else {
                Update-Module @UpdateModuleSplat
            }

        }
    }
}





Invoke-ModuleRequirement -Name "Az.Accounts" -Repository "PSGallery" -SuperVerbose

# but... let's splat it
$InvokeModuleRequirementSplat = @{
    Name = "Az.Accounts"
    Repository = "PSGallery"
    Verbose = $true
}
Invoke-ModuleRequirement @InvokeModuleRequirementSplat