### Splatting 101
### 01 - Splatting Basics

Set-Location $PSScriptRoot
& { break } # no F5ing!

#########################################################################


# Basic cmdlet call
Invoke-RestMethod -Uri "http://ip-api.com/json/?fields=51462"

# we don't care about HTTP errors
Invoke-RestMethod -Uri "http://ip-api.com/json/?fields=51462" -SkipHttpErrorCheck

# we also don't care about certificates
Invoke-RestMethod -Uri "http://ip-api.com/json/?fields=51462" -SkipHttpErrorCheck -SkipCertificateCheck

# we'd better save this as it's quite important
Invoke-RestMethod -Uri "http://ip-api.com/json/?fields=51462" -SkipHttpErrorCheck -SkipCertificateCheck -OutFile ".\Outputs\Geolocate.json"

# we also want to use a custom User-Agent and accept JSON
Invoke-RestMethod -Uri "http://ip-api.com/json/?fields=51462" -SkipHttpErrorCheck -SkipCertificateCheck -OutFile ".\Outputs\Geolocate.json" -Headers @{
    "User-Agent" = "PowerShell-Training-Splatting"
    "Accept"     = "application/json"
} -Verbose




# again, but with splatting!

$InvokeRestMethodSplat = [ordered]@{
    Uri                  = "http://ip-api.com/json/?fields=51462"
    SkipHttpErrorCheck   = $true
    SkipCertificateCheck = $true
    OutFile              = ".\Outputs\GeolocateSplatted.json"
    Headers              = @{
        "User-Agent" = "PowerShell-Training-Splatting"
        "Accept"     = "application/json"
    }
    Verbose              = $true
}

Invoke-RestMethod @InvokeRestMethodSplat

Get-Content -Path ".\Outputs\GeolocateSplatted.json" | ConvertFrom-Json



# using graph appregs? splat it!

$ConnectMGSplat = @{
    CertificateThumbprint = 'C30E848031828699DB3841E39D15A37983343513'
    ClientId              = "7dadc896-899d-46a4-b998-be806e4e2300" # the ID of the app registration, not a secret key
    TenantId              = "f402c7e5-89bd-47d7-a051-8842e2f12757" # the Azure tenant ID, not a secret key
}

Connect-MgGraph @ConnectMGSplat




# many other cmdlets have MANY parameters

$ModuleManifestSplat = @{
    Path          = ".\Outputs\SplattItt.psd1"
    Guid          = (New-Guid).guid
    Author        = $env:USERNAME
    Copyright     = "© $env:USERNAME $((Get-Date).Year)"
    Description   = "A module for splatting it, itt, and other things, created $(Get-Date -Format FileDateTime  )."
    RootModule    = ".\Outputs\SplatItt.psm1"
    ModuleVersion = "1.0.0.1"
}

New-PSModuleManifest @ModuleManifestSplat






### or...

$BootableMediaSplatDynamic = @{
    AllowUnknownMachine   = $true
    AllowUACPrompt        = $true
    SiteCode              = "SMM"
    BootImage             = (Get-CMBootImage -PackageId SMM0048B)
    CertificateExpireTime = ((Get-Date).AddYears(1))
    CertificateStartTime  = (Get-Date)
    DistributionPoint     = (Get-CMDistributionPoint -SiteSystemServerName RealSCCMServer01.contoso.corp)
}

$OtherParamSplat =  @{ 
    UserDeviceAffinity    = "DoNotAllow"
    MediaType             = "CdDvd"
    ManagementPoint       = (Get-CMManagementPoint)[0]
    MediaMode             = "Dynamic"
    Path                  = "c:\ISO\SMM_BootMedia-$(Get-Date -Format filedatetime)-dynamic.iso"
}

New-CMBootableMedia @BootableMediaSplatDynamic @OtherParamSplat -Whatif



