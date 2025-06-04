# Axway vaPublisher Builder Script (PowerShell Version)
# Last Modified: 06-04-25
# Description: Transforms CRL endpoint list into valid vaPublisher format for CRL file import

# Prompt for CRL endpoint list input
$crlEndpointList = Read-Host "Input CRL endpoint list (path to file)"

# Read all lines from the file
$endpoints = Get-Content $crlEndpointList
$numInputs = $endpoints.Count

# Prepare the output content
$output = @()
$output += "[VAPublisher]"
$output += "NUM_INPUT_LOCATIONS=$numInputs"

for ($i = 0; $i -lt $numInputs; $i++) {
    $index = $i + 1
    $location = $endpoints[$i].Trim()
    $output += "[INPUT_SECTION_$index]"
    $output += "LOCATION=CRL;DER;$location"
    $output += "SCHEDULE_CRON_STRING=0 0,6,12,18 * * * *"
    $output += "RETRY_COUNT=3"
    $output += "RETRY_FREQUENCY=20"
}

# Generate the output file name
$date = Get-Date -Format "yyyy-MM-dd"
$outputFile = "vaPublisher.$date"

# Write the result to the output file
$output | Set-Content -Encoding UTF8 $outputFile

Write-Host "File '$outputFile' generated successfully."
