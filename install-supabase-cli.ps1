# Install Supabase CLI on Windows
# This script downloads and installs the Supabase CLI

Write-Host "Installing Supabase CLI..." -ForegroundColor Green

# Create temp directory
$tempDir = "$env:TEMP\supabase-install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download the latest release
$downloadUrl = "https://github.com/supabase/cli/releases/latest/download/supabase_windows_amd64.zip"
$zipFile = "$tempDir\supabase.zip"

Write-Host "Downloading Supabase CLI..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $tempDir -Force

# Create installation directory
$installDir = "$env:LOCALAPPDATA\supabase"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Copy executable
Copy-Item "$tempDir\supabase.exe" -Destination "$installDir\supabase.exe" -Force

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$installDir*") {
    Write-Host "Adding to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host ""
Write-Host "✅ Supabase CLI installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  IMPORTANT: Close and reopen your terminal for the PATH changes to take effect" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then run: supabase --version" -ForegroundColor Cyan
