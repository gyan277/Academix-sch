# Manual Supabase CLI Installation
Write-Host "Downloading Supabase CLI..." -ForegroundColor Green

# Get the latest release info
$apiUrl = "https://api.github.com/repos/supabase/cli/releases/latest"
$release = Invoke-RestMethod -Uri $apiUrl
$asset = $release.assets | Where-Object { $_.name -like "*windows*amd64*.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Host "❌ Could not find Windows release" -ForegroundColor Red
    exit 1
}

$downloadUrl = $asset.browser_download_url
Write-Host "Found: $($asset.name)" -ForegroundColor Yellow
Write-Host "Downloading from: $downloadUrl" -ForegroundColor Cyan

# Create temp directory
$tempDir = "$env:TEMP\supabase-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download
$zipFile = "$tempDir\supabase.zip"
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    Write-Host "✅ Downloaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Download failed: $_" -ForegroundColor Red
    exit 1
}

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

# Find the exe
$exePath = Get-ChildItem -Path $tempDir -Filter "supabase.exe" -Recurse | Select-Object -First 1

if (-not $exePath) {
    Write-Host "❌ Could not find supabase.exe in the archive" -ForegroundColor Red
    exit 1
}

# Create installation directory
$installDir = "$env:LOCALAPPDATA\supabase"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Copy executable
Copy-Item $exePath.FullName -Destination "$installDir\supabase.exe" -Force
Write-Host "✅ Installed to: $installDir\supabase.exe" -ForegroundColor Green

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$installDir*") {
    Write-Host "Adding to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
    $env:Path = "$env:Path;$installDir"  # Update current session
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "✅ Supabase CLI installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Testing installation..." -ForegroundColor Yellow
& "$installDir\supabase.exe" --version

Write-Host ""
Write-Host "✅ Ready to use! You can now run: supabase login" -ForegroundColor Green
