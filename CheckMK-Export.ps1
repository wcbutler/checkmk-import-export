# Define the CSV file path for export
$exportCsvFilePath = "C:\Users\wcbutler\Downloads\checkmk-exports.csv"

# Define CheckMK API details
$checkMKInstance = "https://yoursite.com"
$apiUser = "automation"
$apiSecret = "yourapikey"  # Consider using a secure method to handle this

# Function to get hosts from CheckMK
function Get-HostsFromCheckMK {
    $apiUrl = "$checkMKInstance/check_mk/api/v0/domain-types/host_config/collections/all"
    $headers = @{
        "Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${apiUser}:${apiSecret}")))"
        "Accept" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers
        Write-Output "Successfully retrieved hosts from CheckMK."
        return $response.value
    } catch {
        Write-Error "Failed to get hosts from CheckMK. Error: $_"
        return @()
    }
}

# Get hosts from CheckMK
$hostsData = Get-HostsFromCheckMK

# Check if any hosts were retrieved
if ($hostsData.Count -eq 0) {
    Write-Error "No hosts retrieved from CheckMK."
} else {
    Write-Output "Number of hosts retrieved: $($hostsData.Count)"
}

# Inspect the structure of the first host object
if ($hostsData.Count -gt 0) {
    Write-Output "First host object structure:"
    $hostsData[0] | ConvertTo-Json -Depth 3
}

$exportData = @()
foreach ($hostData in $hostsData) {
    Write-Output "Processing host: $($hostData.id)"
    $exportData += [PSCustomObject]@{
        host_name   = $hostData.id
        device      = $hostData.extensions.attributes.alias
        ipaddress   = $hostData.extensions.attributes.ipaddress 
        fieldops    = $hostData.extensions.attributes.tag_fieldops #this is a tag that I used
        application = $hostData.extensions.attributes.tag_application #this is a tag that I used
        folder      = $hostData.extensions.folder
    }
}

if ($exportData.Count -eq 0) {
    Write-Error "No data prepared for export."
} else {
    Write-Output "Number of records prepared for export: $($exportData.Count)"
}

$exportData | Export-Csv -Path $exportCsvFilePath -NoTypeInformation

Write-Output "Export completed successfully."