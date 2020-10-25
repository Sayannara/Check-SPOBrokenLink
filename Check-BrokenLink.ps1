﻿# OK => (https|http)://.+?("|')
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

# SIG # Begin signature block
# MIIROQYJKoZIhvcNAQcCoIIRKjCCESYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrMBzo8kKNGq/BopVTpy9o9ak
# tAqggg6zMIIHFTCCBP2gAwIBAgITHQAACtFAvjTDFSExqAAAAAAK0TANBgkqhkiG
# 9w0BAQsFADA4MQswCQYDVQQGEwJDSDEMMAoGA1UEChMDRlZFMRswGQYDVQQDExJG
# VkUtSXNzdWVyLUNBLVNoYTIwHhcNMjAwNTE0MDYzMTI0WhcNMjQwNTEzMDYzMTI0
# WjAlMSMwIQYDVQQDDBpGVkVfUG93ZXJTaGVsbF8yMDIwX1NIQTI1NjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBAKBGjjvorDOjj0Lbgf0VWcdTtIH9H+wA
# 7wrTcJCZGFWfxtnoEz5sUg7u1KALTehEI3OXnRb9a20iqq9RJKivQ/mjbBUGc1e7
# k4QAzXYj5triQn0jLv2ACa238R5wC/BFfUo+zYfgTRCSVNUb1F9lBSNzv3Z58ZHx
# 8c7xwvnyi7H2LfDLGJdKl4y17lfd9Gqjl3H2CkMaiccW9OYa8XPFFOxydOC0eHcQ
# lnc0KKE11+Ufs7uq7IdbIRQDGHZKxVmf1eDhdsb7HUpxqr/b0mXiqhTRjIvIpv3n
# UIT9X+CSaOF3iIC4JJm1aNiLtZvltLaDGwCk5Nn739i7+7rvH2RRcw8CAwEAAaOC
# AykwggMlMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcVCIKDnUWHnogigZGTMIPC
# 2jeBg8YGTYaoql6B95xWAgFkAgEPMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1Ud
# DwEB/wQEAwIHgDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQW
# BBRHUxXwDM6m3B6ligB2NL/HdYp3ozAlBgNVHREEHjAcghpGVkVfUG93ZXJTaGVs
# bF8yMDIwX1NIQTI1NjAfBgNVHSMEGDAWgBS8OoUOcc0nS/p/sR6M+ZVfwRO2MjCC
# AQYGA1UdHwSB/jCB+zCB+KCB9aCB8oYxaHR0cDovL3ZhLmZlZG5ldC5sb2NhbC9j
# ZHAvRlZFLUlzc3Vlci1DQS1TaGEyLmNybIaBvGxkYXA6Ly8vQ049RlZFLUlzc3Vl
# ci1DQS1TaGEyLENOPUZFVE8xUzAwNyxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIw
# U2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1mZWRuZXQs
# REM9bG9jYWw/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIIBLwYIKwYBBQUHAQEEggEhMIIBHTA9
# BggrBgEFBQcwAoYxaHR0cDovL3ZhLmZlZG5ldC5sb2NhbC9haWEvRlZFLUlzc3Vl
# ci1DQS1TaGEyLmNydDCBsgYIKwYBBQUHMAKGgaVsZGFwOi8vL0NOPUZWRS1Jc3N1
# ZXItQ0EtU2hhMixDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049
# U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1mZWRuZXQsREM9bG9jYWw/Y0FD
# ZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3Jp
# dHkwJwYIKwYBBQUHMAGGG2h0dHA6Ly92YS5mZWRuZXQubG9jYWwvb2NzcDANBgkq
# hkiG9w0BAQsFAAOCAgEAFKlms7NDKFl2cGZeglWQW22UfCOi0bOUuJg1cAB5ajJ/
# t/QqoXvAaIzlHyKzuBY66n888d5yLoaHE0XjxVvm/ae3R0QHvGoBTT2UCuK7mfEe
# Xv32cORTVgAc/MPLQEtav+2EqLMup8Ghm4RtuxpmWQfmzxnz3j9aZO2t4u/iEbpj
# il/XX2ahUqg1KUo47AIrr4jXPy/5khTK4gW28UbHWmSajIIQMLisVdbNrD+9xQMc
# qGUglSVy0lrJl4heL0r533uf9VRS2Sl8PXnYYEyakWS15+bOKd+j71RfJ6SeQtTg
# 35netTV3etr3BuhYTTZLvdA0k+YljQFa8cdyT+0jR6n1lbtZTqCfjv63SPQOf/fb
# 9sASTH9MWebZmSebWXOkQv5aK++GtwczWaAhxUulAmZ1CIzQN6OjvVbp9wpK7VLo
# 96lmQm9aXHcw355uW8oErcMJr0EItPKMFSxaT8BFlAD3ii5xSfbCrwOWLQ//H+gC
# mq87E8sTwx9EdU9BD5NaRtMkIF0pgQ1YqTYJ336wan2+ctk89XdyDyW8/IgfsNEf
# g0cNQ1ji0lLm3zekuk/346ayoPky3v2SawJ62iUOcwrpP0+Aog2Zhu/afqqWfztj
# 1/FNKnhQ+2IgsyIYDhiWQKwK1VhUuFPu/2so22p+/NnHBGy1C5zLgQlc1fLLk2Aw
# ggeWMIIFfqADAgECAhMnAAAAAyFVpU7QN9teAAAAAAADMA0GCSqGSIb3DQEBCwUA
# MDYxCzAJBgNVBAYTAkNIMQwwCgYDVQQKEwNGVkUxGTAXBgNVBAMTEEZWRS1Sb290
# LUNBLVNoYTIwHhcNMTYwNDA4MTIwNzQwWhcNMzYwNDA4MTIxNzQwWjA4MQswCQYD
# VQQGEwJDSDEMMAoGA1UEChMDRlZFMRswGQYDVQQDExJGVkUtSXNzdWVyLUNBLVNo
# YTIwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCt1vSa649UE8BQkGm+
# QDo7t0WDzBVybMXOCXviN8ais9UV7a4Ra0WyIo/X6HzmKgd38P0NV0tR9sy3qHu3
# +SpMy/87Fdqjqm7yx1+MVMGBJ+ONzCKdP7C7e/n4iEj6cfFZE8zL52GmjFyuZCTN
# KsN9NyPZURbSSYU8Wgv9GamcqNKwCEDr03qsjeN7cdn+ftgCCraxsvJByZQ3Qmck
# NKOTkCiDgGIWhjuPuNUM0KaVCI1MltxiyNLPiLjrVQIgSi6VNd3WWIfhwI0IE5rU
# 6sIOE/D1TcdNGWOWON3HrkseSCZ3AJBPHsN+y2T3uwCWQd8yM617aEeYiKVRKE0B
# aEIBaaXrOcelgWt7mGm/asZ/0J5wiQECSH25mEuY67r+e3QOl9sMpXtLuDoCbksZ
# 1fFaMdsxK/CuO1aAmlK74R8LnZx4khrbdDt8GMYrRIOc/KlBAknpyLBZJN6aT+k9
# hnwsXu/uxF6sygx+XLN0Tm3ZyVCn9Pi+ilxYXXnwEacyyTP2n5/uPQ9EBK2FlQdA
# okPVL45A6c3IuQGQu3+j/ArJFrTu4AA0GRB6IjTr8UcAb8X5nGrDqGrQ8/pEFoWg
# nz1cQk6fuP2HBAheDAMzbI7nQwATx0aGFu9ES6CJrsOJK7QrcDxSknGzTHrC1oSz
# ZjmFYliDlZSMmn+A5Cki+WO+MwIDAQABo4ICmTCCApUwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFLw6hQ5xzSdL+n+xHoz5lV/BE7YyMBkGCSsGAQQBgjcUAgQM
# HgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud
# IwQYMBaAFNSJgUX3JRtX/P/MHbh83sd8qvVYMIIBAgYDVR0fBIH6MIH3MIH0oIHx
# oIHuhi9odHRwOi8vdmEuZmVkbmV0LmxvY2FsL2NkcC9GVkUtUm9vdC1DQS1TaGEy
# LmNybIaBumxkYXA6Ly8vQ049RlZFLVJvb3QtQ0EtU2hhMixDTj1GRVRPMVMwMDYs
# Q049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENO
# PUNvbmZpZ3VyYXRpb24sREM9ZmVkbmV0LERDPWxvY2FsP2NlcnRpZmljYXRlUmV2
# b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2lu
# dDCCAQAGCCsGAQUFBwEBBIHzMIHwMDsGCCsGAQUFBzAChi9odHRwOi8vdmEuZmVk
# bmV0LmxvY2FsL2FpYS9GVkUtUm9vdC1DQS1TaGEyLmNydDCBsAYIKwYBBQUHMAKG
# gaNsZGFwOi8vL0NOPUZWRS1Sb290LUNBLVNoYTIsQ049QUlBLENOPVB1YmxpYyUy
# MEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9
# ZmVkbmV0LERDPWxvY2FsP2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1j
# ZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MA0GCSqGSIb3DQEBCwUAA4ICAQCmwFXDp5fl
# TtCG+AnSgq7QOgG3W8vAEzRcNKC5Kxgpoj7al1kNFKnB2EWg4RUMy4mvxfqW7iEq
# fN71jBkA2k5/+i5Xh7blHiyFsO4W3DyLLqAcdlq+MKxfak5MXMfIL0PbCyEshz+J
# wxH61c+WAEV4POHyB2waRk3SFBKaBHlr4mMN5vqzctgfyGylpGmLYYORk4TBivH8
# cb5EbUp4P6qhOImOTwseZVgQ4J+4SJL3uNrvKSQvU00aZyPXnXBIgKV0dFj6Pbhf
# 7iLqof4oN+A9jv/342ecrVSV4VWDJ54SyaDZ3XP8XhKbXQ5rigTV9Ea6kNAZCtNG
# A95zN8paL+2voAaRSA7ubnPN5mVRLV95V0R36ziQ9xrhGt77uhh3Cx24/h5YpJ/C
# 1OBWs4ofIWS1ksdPvshzPZfrstiRdzJSgaX2hJkFL/CldaE75u/VQzKcrmKaXpWj
# ZUTi/4+k8lLLk2jh8xrE1De2C63Am18iueFdpk5eMI20x6L8W351hv7XRevbLagB
# +M/LHd0Y6r41Iov9FT9DvSA+MOVo2850K9Dlx00K1azGDWlDW9ZmtWXuZtdY5iGz
# AX+awBuCKzNzwm0Y5zgomTb9CCTfaGRw2BqCxRNic1B/Hlbsfd4dxMocKpQzs1Ee
# MfrXKuZsoYONHE4WXS49M2fPO+Wq5HpJvDGCAfAwggHsAgEBME8wODELMAkGA1UE
# BhMCQ0gxDDAKBgNVBAoTA0ZWRTEbMBkGA1UEAxMSRlZFLUlzc3Vlci1DQS1TaGEy
# AhMdAAAK0UC+NMMVITGoAAAAAArRMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR6cTB6UBGUXWsK
# RzxFx9w7lYbouzANBgkqhkiG9w0BAQEFAASCAQBgjHGcT1toAVXHD+EyyvYnhxet
# chCidb+hSLU9DEO6H+KzacJQeFo1k2JUSGatgn9dFmkvsNEGkEJhJtFBYlGvk4GQ
# lPszdGDsD6iEzBWVehM3gadgzMYrccYR8Zw6Ls1HfgRdzq7dFIrJ0VT28rChqYUB
# jQZDXlioFvLlaftPcJOpASRnxTMTH8eCAVCsoQH1mgNS1q+OJMuvCdNeyoLLaqvB
# SXTyiuh7LMiN1Sp2KVs3B5z4ICcsdRqycxZOqJvR8RpImQyE58xR+fzHKJPFdCgO
# VhLrLZ3VXsF/SPvZq5GUPSDjvKe+uyhUeZUHt9sxlvDnTurkK16Ekw1qaEV0
# SIG # End signature block
