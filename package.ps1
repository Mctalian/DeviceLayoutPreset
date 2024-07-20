# PowerShell script to package the DeviceLayoutPreset addon

#region: Variables
$currentDirectory = Get-Location
$licenseFile = Join-Path -Path $currentDirectory -ChildPath "LICENSE"
$readmeFile = Join-Path -Path $currentDirectory -ChildPath "README.md"
$sourceDirectory = Join-Path -Path $currentDirectory -ChildPath "DeviceLayoutPreset"
$destinationZip = Join-Path -Path $currentDirectory -ChildPath "DeviceLayoutPreset.zip"
$tempLicenseFile = Join-Path -Path $sourceDirectory -ChildPath "LICENSE"
$tempReadmeFile = Join-Path -Path $sourceDirectory -ChildPath "README.md"
#endregion: Variables

#region: Zip cleanup
if (Test-Path $destinationZip) {
    Remove-Item $destinationZip -Force
}
#endregion: Zip cleanup

#region: Include License and README.md files
if (Test-Path $licenseFile) {
  Copy-Item -Path $licenseFile -Destination $sourceDirectory -Force
} else {
  Write-Warning "LICENSE file not found in the current directory."
}

if (Test-Path $readmeFile) {
  Copy-Item -Path $readmeFile -Destination $sourceDirectory -Force
} else {
  Write-Warning "README.md file not found in the current directory."
}
#endregion: Include License and README.md files

#region: Create ZIP archive
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourceDirectory, $destinationZip)
} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
#endregion: Create ZIP archive

#region: Cleanup
if (Test-Path $tempLicenseFile) {
  Remove-Item -Path $tempLicenseFile -Force
}

if (Test-Path $tempReadmeFile) {
  Remove-Item -Path $tempReadmeFile -Force
}
#endregion: Cleanup

Write-Output "ZIP archive creation process completed."
