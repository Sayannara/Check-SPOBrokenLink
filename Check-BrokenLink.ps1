# OK => (https|http)://.+?("|')
# OK => \b(([\w-]+://?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|/)))
# https://mathiasbynens.be/demo/url-regex
# https://regex101.com/

# Variables 
##################################################################################################
cls
   
. ".\Get-SPSitePagesContent.ps1"
. ".\Encode-HumanReadability.ps1"
. ".\Test-URL.ps1"

$ArrayURLStatus = @()

# It seems that it is mandatory to authenticate on the root site for the connection to work
Connect-PnPOnline -url "https://MyTenant.sharepoint.com" -ClientId "" -ClientSecret ""

# START
##################################################################################################


# List all sites
$TenantSites = Get-PnPTenantSite | ? {($_.Template -eq "SitePagePublishing#0" -and ($_.URL -eq "https://MyTenant.sharepoint.com/sites/INF")) } | Select -ExpandProperty URL  # -and ($_.URL -eq "https://MyTenant.sharepoint.com/sites/INF") Add filter hrere for your tests

# pour chaque site sur le tenant
foreach($TenantSite in $TenantSites){
    $i = $i + 1
    Write-Progress -Activity Updating -Status 'Progress->' -PercentComplete ($i/$TenantSites.Count*100) -CurrentOperation "Site collections"
    write-host "`nTenantSite: $TenantSite" -b Yellow
    
    # Obtenir le contenu de toutes les pages du site
    $TenantSitePages = Get-SPSitePagesContent -SiteURL $TenantSite -Library "Pages%20du%20site" | ? Title -like B* # Add filter hrere for your tests
    
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


Connect-PnPOnline -url "https://MyTenant.sharepoint.com/sites/config" -ClientID "" -ClientSecret ""
# Remove all items
$List = "Vérification liens sites"

$Items = Get-PnPListItem -List $List
foreach($item in $items){
    Remove-PnPListItem -List $List -Identity $Item.id -Force
}

# Add items
foreach($URL in $ArrayURLStatus){
    if($URL.Status -eq "NOK"){
        Add-PnPListItem -list $List -Values @{"Title" = $URL.Site; "Page" = $URL.Page; "URL" = $URL.URL; "Statut" = $URL.Status}
    }
}
