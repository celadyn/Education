function IsASplat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    if ($InputObject -is [hashtable] -or $InputObject -is [array]) {
        return $true
    } else {
        $false
    }
}
 