# Welcome
Check-SPOBrokenLink detects and lists all broken links within SharePoint Online sites.

As is, this is my tool to check broken links in SharePoint Online. The tool need many improvments. Feel free to use it add features and share it.

# How to use it ?
1. Download all the files a put them all in a same directory
2. Adapt the connection to your tenant - Connect-PnPOnline
3. Adapt the variale $TenantSites, check the filter
4. Adapt the variable $TenantSitePages, you'll probably want "SitePages", check the filter

# Pending improvments
1. Find a better regex pattern to identify URL
2. Consider using ConvertFrom-Json to obtain an object of the page's content
3. Currently pages are checked, we need to look in libraries too
4. Improve code in general
