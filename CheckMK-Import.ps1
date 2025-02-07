# Define the CSV file path
$csvFilePath = "C:\Users\wcbutler\Downloads\devices-fixed.csv"

# Import the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Define CheckMK API details
$checkMKInstance = "https://yoursite.com"
$apiUser = "automation"
$apiSecret = "yourapisecret"  # Consider using a secure method to handle this

function Add-HostToCheckMK {
    param (
        [string]$device,
        [string]$host_name,
        [string]$ipaddress,
        [string]$tags,
        [string]$folder
    )

    $apiUrl = "$checkMKInstance/check_mk/api/v0/domain-types/host_config/collections/all"
    $headers = @{
        "Authorization" = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${apiUser}:${apiSecret}")))"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    $body = @{
        host_name = $host_name
        folder = "~test"
        attributes = @{
            alias = $device
            tag_yourcreatedtag = $folder  #Tag group name must start with 'tag_' and you will need to set it up in the UI. The UI won't name it with the tag_ for you either.
        }
    }

    if ($ipaddress) {
        $body.attributes.ipaddress = $ipaddress
    }

    $bodyJson = $body | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $bodyJson
        Write-Output "Successfully added host: $host_name"
    } catch {
        Write-Error "Failed to add host: $host_name. Error: $_"
    }
}

foreach ($row in $csvData) {
    $ipaddress = (Resolve-DnsName -Name $row.host -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ","
    Add-HostToCheckMK -device $row.device -host_name $row.host -ipaddress $ipaddress -tags $row.tags -folder $row.group
}

Write-Output "Import completed successfully."