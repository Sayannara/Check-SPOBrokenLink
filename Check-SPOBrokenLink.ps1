# Variables 
##################################################################################################
cls

$path = $myInvocation.invocationName; $path = split-path -parent $path; set-location $path 
   
. ".\Get-SPSitePagesContent.ps1"
. ".\Encode-HumanReadability.ps1"
. ".\Test-URL.ps1"

$ArrayURLStatus = @()
$MyTenantURL = "https://MyTenant.sharepoint.com"
$ClientID = ""
$ClientSecret = ""
$Library = "Pages%20du%20site" # depends of the site's language
$i = 0
$j = 0

# List all sites
$TenantSites = Get-PnPTenantSite | ? {($_.Template -eq "SitePagePublishing#0") } | Select -ExpandProperty URL  # -and ($_.URL -eq "$MyTenantURL/sites/INF") Add filter hrere for your tests

# It seems that it is mandatory to authenticate on the root site for the connection to work
Connect-PnPOnline -url $MyTenantURL -ClientId $ClientID -ClientSecret $ClientSecret

# START
##################################################################################################

# pour chaque site sur le tenant
foreach($TenantSite in $TenantSites){
    $i = $i + 1
    Write-Progress -Activity Updating -Status 'Progress->' -PercentComplete ($i/$TenantSites.Count*100) -CurrentOperation "Site collections"
    write-host "`nTenantSite: $TenantSite" -b Yellow
    
    # Obtenir le contenu de toutes les pages du site
    $TenantSitePages = Get-SPSitePagesContent -SiteURL $TenantSite -Library $Library #| ? Title -like B* # Add filter hrere for your tests
    
    # pour chaque pages que détient le Tenant, modifier le contenu pour que l'encodage soit lisible
    foreach($TenantSitePage in $TenantSitePages){
        $j = $j + 1
        Write-Progress -Id 1 -Activity Updating -Status 'Progress' -PercentComplete ($j/$TenantSitePages.Count*100) -CurrentOperation "Pages"
        write-host "`nTenantSitePage" -b Yellow
        $TenantSitePage.Title

        $TenantSitePageContentHumans = Encode-HumanReadability -ContentRaw $TenantSitePage.Content
        
        write-host "TenantSitePageContentHumans" -b Yellow
        $TenantSitePageContentHumans

        # the pattern used which look for the last char ("|'). This is the only way I found to delimit URL. 
        $TenantSitePageContentHumanURLs = $TenantSitePageContentHumans | select-string -Pattern "(https|http)://.+?(`"|')" -AllMatches
        write-host "TenantSitePageContentHumanURLs" -b Yellow
        $TenantSitePageContentHumanURLs

        # $TenantSitePageContentHumanURLsNumberMatches = $TenantSitePageContentHumanURLs.matches.index.Count

        # As is, if $TenantSitePageContentHumanURLs is empty, an error occurs
        foreach($TenantSitePageContentHumanURL in $TenantSitePageContentHumanURLs[0].Matches ){
            write-host "`nTenantSitePageContentHumanURL: $TenantSitePageContentHumanURL" -b Yellow

            # We could try to clean the URL
            $TenantSitePageContentHumanURL = $TenantSitePageContentHumanURL.Value.Replace('"',"")

            $URLStatus = Test-URL $TenantSitePageContentHumanURL

            $ObjURLStatus = [PSCustomObject]@{
                Site = $TenantSite
                Page = $TenantSitePage.Title
                MatchID = $TenantSitePageContentHumanURLs.Matches.Index
                URL = $TenantSitePageContentHumanURL
                Status = $URLStatus
            }

            $ArrayURLStatus += $ObjURLStatus 
        }
    }
}

$ArrayURLStatus | ft
