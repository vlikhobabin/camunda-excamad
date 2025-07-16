# PowerShell script for deploying nginx configurations to server
# Author: EXCAMAD Project
# Description: Automatic deployment of all nginx configurations to remote server

param(
    [string]$ServerIP = "109.172.36.204",
    [string]$Username = "root",
    [string]$RemotePath = "/etc/nginx/sites-available",
    [switch]$DryRun,
    [switch]$EnableSites
)

# Settings
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    if ($Host.UI.RawUI.ForegroundColor) {
        $fc = $host.UI.RawUI.ForegroundColor
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
        if ($args) {
            Write-Output $args
        } else {
            $input | Write-Output
        }
        $host.UI.RawUI.ForegroundColor = $fc
    } else {
        if ($args) {
            Write-Output $args
        } else {
            $input | Write-Output
        }
    }
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }
function Write-Info { Write-ColorOutput Cyan $args }

# Check if pscp is available
function Test-PscpAvailable {
    try {
        $null = Get-Command pscp -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Function to deploy nginx file
function Deploy-NginxFile {
    param(
        [string]$FilePath,
        [string]$RemoteDestination
    )
    
    $fileName = Split-Path $FilePath -Leaf
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    Write-Info "Sending: $fileName"
    
    if ($DryRun) {
        Write-Warning "DRY RUN: pscp `"$FilePath`" $Username@${ServerIP}:$RemoteDestination"
        return $true
    }
    
    try {
        $pscpArgs = @(
            "`"$FilePath`"",
            "$Username@${ServerIP}:$RemoteDestination"
        )
        
        Start-Process -FilePath "pscp" -ArgumentList $pscpArgs -Wait -NoNewWindow
        Write-Success "Successfully sent: $fileName"
        return $true
    } catch {
        Write-Error "Error sending $fileName : $($_.Exception.Message)"
        return $false
    }
}

# Function to enable nginx sites
function Enable-NginxSite {
    param([string]$SiteName)
    
    if ($DryRun) {
        Write-Warning "DRY RUN: Enabling site $SiteName"
        return $true
    }
    
    Write-Info "Enabling site: $SiteName"
    
    $sshCommand = "ln -sf /etc/nginx/sites-available/$SiteName /etc/nginx/sites-enabled/$SiteName"
    
    try {
        $process = Start-Process -FilePath "plink" -ArgumentList @(
            "-batch",
            "$Username@$ServerIP",
            "`"$sshCommand`""
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Site enabled: $SiteName"
            return $true
        } else {
            Write-Error "Error enabling site: $SiteName"
            return $false
        }
    } catch {
        Write-Error "Error executing command: $($_.Exception.Message)"
        return $false
    }
}

# Function to test nginx configuration
function Test-NginxConfig {
    if ($DryRun) {
        Write-Warning "DRY RUN: Testing nginx configuration"
        return $true
    }
    
    Write-Info "Testing nginx configuration..."
    
    try {
        $process = Start-Process -FilePath "plink" -ArgumentList @(
            "-batch",
            "$Username@$ServerIP",
            "nginx -t"
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Nginx configuration is valid"
            return $true
        } else {
            Write-Error "Nginx configuration errors found!"
            return $false
        }
    } catch {
        Write-Error "Error testing configuration: $($_.Exception.Message)"
        return $false
    }
}

# Function to restart nginx
function Restart-Nginx {
    if ($DryRun) {
        Write-Warning "DRY RUN: Restarting nginx"
        return $true
    }
    
    Write-Info "Restarting nginx..."
    
    try {
        $process = Start-Process -FilePath "plink" -ArgumentList @(
            "-batch",
            "$Username@$ServerIP",
            "systemctl reload nginx"
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Nginx restarted successfully"
            return $true
        } else {
            Write-Error "Error restarting nginx"
            return $false
        }
    } catch {
        Write-Error "Error executing command: $($_.Exception.Message)"
        return $false
    }
}

# Main function
function Main {
    Write-Info "Starting nginx configurations deployment..."
    Write-Info "Server: $ServerIP"
    Write-Info "User: $Username"
    Write-Info "Remote path: $RemotePath"
    
    # Get script directory
    $scriptDir = $PSScriptRoot
    Write-Info "Looking for nginx files in: $scriptDir"
    
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - files will not be sent"
    }
    
    # Check pscp availability
    if (-not (Test-PscpAvailable)) {
        Write-Error "pscp not found! Make sure PuTTY is installed and pscp is available in PATH"
        exit 1
    }
    
    # Get all nginx files - look in script directory
    $fileNames = @("camunda", "camunda.eg-holding.ru", "excamad.eg-holding.ru")
    $nginxFiles = Get-ChildItem -Path $scriptDir -File | Where-Object { $fileNames -contains $_.Name }
    
    if ($nginxFiles.Count -eq 0) {
        Write-Warning "No nginx files found in script directory: $scriptDir"
        Write-Info "Looking for files: camunda, camunda.eg-holding.ru, excamad.eg-holding.ru"
        exit 1
    }
    
    Write-Info "Found files: $($nginxFiles.Count)"
    
    $successCount = 0
    $sitesToEnable = @()
    
    # Deploy files
    foreach ($file in $nginxFiles) {
        if (Deploy-NginxFile -FilePath $file.FullName -RemoteDestination $RemotePath) {
            $successCount++
            $sitesToEnable += $file.Name
        }
    }
    
    Write-Info "Result: $successCount of $($nginxFiles.Count) files sent successfully"
    
    if ($successCount -eq 0) {
        Write-Error "No files were sent successfully"
        exit 1
    }
    
    # Enable sites if specified
    if ($EnableSites -and $sitesToEnable.Count -gt 0) {
        Write-Info "Enabling sites..."
        foreach ($site in $sitesToEnable) {
            Enable-NginxSite -SiteName $site
        }
    }
    
    # Test configuration
    if (Test-NginxConfig) {
        # Restart nginx
        Restart-Nginx
        Write-Success "Deployment completed successfully!"
    } else {
        Write-Error "Deployment aborted due to configuration errors"
        exit 1
    }
}

# Help
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "-h") {
    Write-Host @"
Nginx Configuration Deployment Script

USAGE:
    .\deploy-nginx.ps1 [parameters]

PARAMETERS:
    -ServerIP [IP]        Server IP address (default: 109.172.36.204)
    -Username [user]      Username (default: root)
    -RemotePath [path]    Remote path (default: /etc/nginx/sites-available)
    -DryRun              Test mode (files will not be sent)
    -EnableSites         Automatically enable sites after deployment
    -help                Show this help

EXAMPLES:
    .\deploy-nginx.ps1                                    # Basic deployment
    .\deploy-nginx.ps1 -DryRun                           # Test run
    .\deploy-nginx.ps1 -EnableSites                      # Deploy with site enabling
    .\deploy-nginx.ps1 -ServerIP "192.168.1.100"        # Different server

REQUIREMENTS:
    - PuTTY (pscp and plink) must be installed and available in PATH
    - SSH authentication configured on server
"@
    exit 0
}

# Run main function
try {
    Main
} catch {
    Write-Error "Critical error: $($_.Exception.Message)"
    exit 1
} 