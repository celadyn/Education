`Published at: https://dev.to/celadin/get-mggraphallpages-the-mggraph-missing-command-45b5`

# Get-MgGraphAllPages: The MgGraph Missing Command



PowerShell is awesome. Microsoft Graph, quirks aside, is also awesome. The latest iteration of the [Microsoft Graph Powershell module](https://learn.microsoft.com/en-us/powershell/microsoftgraph/overview?view=graph-powershell-beta), released in 2022, lets you use PowerShell cmdlets for graph management operations, to the extent that those operations are documented by the Graph API docs is available as a PS command.

The documentation portion is important because this module is automatically-generated (autorest) from the graph API SDK. And that means it is _expansive_:

```powershell 
♥PS> Get-Command "*-mg*" | group commandtype | select count,name

Count Name    
----- ----    
  356 Alias   
 6861 Function
   10 Cmdlet  
```

In a perfect world this would be everything you ever need to do with Graph. Built-in params on each command/function make it easy to get all result pages, include filters, set a sortby, etc. Convenient!

However. Sometimes, you'll end up with a raw Graph URI. And, while you could drop that into `Find-MgGraphCommand`, let's imagine you'd rather work with the raw URI - maybe you're bouncing between Graph Explorer or working with the MS support team on a ticket or validating a non-PowerShell direct-HTTP use case, or something else which makes URIs easier/faster.

Fortunately, the MgGraph module has a solution: if you find yourself faced with with raw Graph URIs (e.g., `"https://graph.microsoft.com/beta/deviceManagement/managedDevices/9f2867b1-ddfb-4d9c-a2db-3ab3faf7d5bf/detectedApps"`) you can use `Invoke-MgGraphRequest` (it handles all the authentication bits but allows you to fully customize the request otherwise:

For example:
```powershell
♥PS> $MGRSplat = @{ 
    Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/9f2867b1-ddfb-4d9c-a2db-3ab3faf7d5bf/detectedApps"
    Method = "GET"
} 
♥PS> $Results = Invoke-MgGraphRequest @MGRSplat
♥PS> $Results.count

4
```
Invoke-MgGraphRequest is invaluable, but you may notice the returned content is simply the objects requested. For example, this result for `detectedApp`s from a single device is allegedly only 4 results? We all know there's no device in existence with only 4 detectedApps. Instead, `$results` is returned odata meta object:

```powershell
♥PS> $Results

Name                           Value                                                                                                              
----                           -----                                                                                                              
@odata.context                 https://graph.microsoft.com/beta/$metadata#Collection(microsoft.graph.detectedApp)                                 
@odata.count                   177                                                                                                                
@odata.nextLink                https://graph.microsoft.com/beta/deviceManagement/managedDevices/9f2867b1-ddfb-4d9c-a2db-3ab3faf7d5bf/detectedAp...
value                          {System.Collections.Hashtable, System.Collections.Hashtable, System.Collections.Hashtable, System.Collections.Ha...
```

Here, instead of an array of values, this particular API returns the values AND response metadata. The metadata is helpful, as it confirms which endpoint responded and how, does (when possible) count the amount of results, and then also provides the `value` property which contains the actual returned values.

Note however the `@odata.nextlink`: this means that the returned values are not ALL of the values, but only a portion. This API is subject to paging, and we'll have to follow the pages down to eventually return all the results.

Paging in Graph is difficult to predict ([the docs](https://learn.microsoft.com/en-us/graph/paging) just say "Different APIs might have different default and maximum page sizes"). However, assume most/all API endpoints will fall to paging after a certain number of results. Could be 2, could be 100, could be 1000. (It might also be tenant specific - not sure. In my tenant, the `users` endpoint returns 100 item pages, while `managedDevices` returns 1000 item pages.)

Fortunately, the @odata.nextLink isn't hard to deal with, and each of the `Get-MgGraph*` commands include an `-All` parameter which handles it for you.

Unfortunately, `Invoke-MgGraphRequest` (while fully capable of GETs) is an `Invoke`, not a `Get`. Consequently, it does not have an `-All` parameter. And, there's no easy or pre-existing command in the MgGraph module you can pipe to like, to just make up a hypothetical command name, `Get-MgGraphAllPages`. 

So, let's make one! But - not from scratch. We might be able to do a bit of pilfering. Great artists, here.

Our potential source: prior to the introduction of the M*g*Graph module, Microsoft published the "M*S*Graph" module (aka [Microsoft.Graph.Intune](https://www.powershellgallery.com/packages/Microsoft.Graph.Intune/6.1907.1.0)). This module is abandoned, but long story short it contains one VERY handy command: `Get-MSGraphAllPages`.

We can just pull the code out of this, right? Well, probably not. Where the M*g*Graph commands are almost all functions, the M*S*Graph commands are almost all binary cmdlets...

```powershell
♥PS> Get-Command -Module Microsoft.Graph.Intune | group commandtype 

Count Name                      Group                                                                                                             
----- ----                      -----                                                                                                             
  510 Alias                     {Get-AADGroup, Get-AADGroupCreatedOnBehalfOf, Get-AADGroupCreatedOnBehalfOfReference, Get-AADGroupGroupLifecycl...
    3 Function                  {Get-MSGraphAllPages, Get-MSGraphDebugInfo, Set-MSGraphAlias}                                                     
 1056 Cmdlet                    {Connect-MSGraph, Get-DeviceAppManagement, Get-DeviceAppManagement_AndroidManagedAppProtections, Get-DeviceAppM...
```

...except, amazingly, 3 - including `Get-MSGraphAllPages`. Many thanks to the module author here at Microsoft, they've gave us quite a gift.

Why this matters: you cannot view the source code behind binary cmdlets in Powershell - it is compiled into DLLs. However, functions expose their code freely.

We'll use the `function:` provider to get function info by name, and then pull the function's definition right from that object:

```powershell
♥PS> Get-Item function:Get-MsGraphAllPages | select -ExpandProperty definition

    [CmdletBinding(
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'SearchResult'
    )]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'NextLink', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('@odata.nextLink')]
        [string]$NextLink,

        [Parameter(Mandatory = $true, ParameterSetName = 'SearchResult', ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSObject]$SearchResult
    )

    begin {}

    process {
        if ($PSCmdlet.ParameterSetName -eq 'SearchResult') {
            # Set the current page to the search result provided
            $page = $SearchResult

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # We know this is a wrapper object if it has an "@odata.context" property
            if (Get-Member -InputObject $page -Name '@odata.context' -Membertype Properties) {
                $values = $page.value
            } else {
                $values = $page
            }

            # Output the values
            if ($values) {
                $values | Write-Output
            }
        }

        while (-Not ([string]::IsNullOrWhiteSpace($currentNextLink)))
        {
            # Make the call to get the next page
            try {
                $page = Get-MSGraphNextPage -NextLink $currentNextLink
            } catch {
                throw
            }

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # Output the items in the page
            $values = $page.value
            if ($values) {
                $values | Write-Output
            }
        }
    }

    end {}

```

This is the actual code behind this function, directly from the module, authored by someone at Microsoft. And, impressively, it's both well-commented and not doing anything tricky - just parses the returned odata object for the nextLink page links, queries them until there's none left, and dumps the output to the pipeline as it goes. In fact, we COULD just pipe the result of `Invoke-MgGraphRequest` straight into `Get-MsGraphAllPages` and it will... almost work.

Almost, though, isn't good enough. And besides that, this module is abandoned (not updated since 2019), and the Microsoft.Graph.Intune cmdlets are probably soon-deprecated 
(maybe - MS keeps delaying and it's a [confusing](https://www.reddit.com/r/PowerShell/comments/10zelnv/microsoftgraphintune_going_away/) [topic](https://learn.microsoft.com/en-us/graph/migrate-azure-ad-graph-faq)). So, while they're still on the PSGallery, better to be rid of that dependency.

A couple necessary tweaks are required to turn Get-M*S*GraphAllPages into Get-M*g*GraphAllPages:

1. Swap `Get-MSGraphNextPage` with a nested `Invoke-MgGraphRequest`. `Get-MSGraphNextPage` is a binary cmdlet from Microsoft.Graph.Intune and thus unwelcome.
2. MgGraph invocations return hashtables, not objects, so we need to modify the bit which checks the returned response to properly emit only values and not meta-responses.
3. `@odata.context` is returned on all requests, so what we really need to check for is `@odata.nextLink`.

For my own sake, I've added a handful of other niceties. Nothing exceptionally fancy, and the whole thing COULD be made slightly more streamlined, but that can come later.

Anyway, after all that module spelunking and a few lines of code -- `Get-MgGraphAllPages`:

```powershell
function Get-MgGraphAllPages {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'SearchResult'
    )]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'NextLink', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('@odata.nextLink')]
        [string]$NextLink
        ,
        [Parameter(Mandatory = $true, ParameterSetName = 'SearchResult', ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSObject]$SearchResult
        ,
        [Parameter(Mandatory = $false)]
        [switch]$ToPSCustomObject
    )

    begin {}

    process {
        if ($PSCmdlet.ParameterSetName -eq 'SearchResult') {
            # Set the current page to the search result provided
            $page = $SearchResult

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # We know this is a wrapper object if it has an "@odata.context" property
            #if (Get-Member -InputObject $page -Name '@odata.context' -Membertype Properties) {
            # MgGraph update - MgGraph returns hashtables, and almost always includes .context
            # instead, let's check for nextlinks specifically as a hashtable key
            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "First page value count: $($Page.'@odata.count')"    
            }

            if ($page.ContainsKey('@odata.nextLink') -or $page.ContainsKey('value')) {
                $values = $page.value
            } else { # this will probably never fire anymore, but maybe.
                $values = $page
            }

            # Output the values
            # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
            if ($values) {
                if ($ToPSCustomObject) {
                    $values | ForEach-Object {[pscustomobject]$_}   
                } else {
                    $values | Write-Output
                }
            }
        }

        while (-Not ([string]::IsNullOrWhiteSpace($currentNextLink)))
        {
            # Make the call to get the next page
            try {
                $page = Invoke-MgGraphRequest -Uri $currentNextLink -Method GET
            } catch {
                throw $_
            }

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # Output the items in the page
            $values = $page.value

            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "Current page value count: $($Page.'@odata.count')"    
            }

            # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
            if ($ToPSCustomObject) {
                $values | ForEach-Object {[pscustomobject]$_}   
            } else {
                $values | Write-Output
            }
        }
    }

    end {}
}
```

It works wonderfully, and is quite a time saver when fiddling with Graph requests in URI form. And now we can uninstall the Microsoft.Graph.Intune module and never think about it again ~~until we need to get iOS activation lock bypass codes or interact with other graph objects inaccessible to the MgGraph commands~~.

Stay tuned for more Powershell + API adventures, and more!