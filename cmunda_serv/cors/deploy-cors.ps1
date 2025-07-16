# PowerShell script for deploying CORS configuration to server
# Author: EXCAMAD Project
# Description: Automatic deployment of web.xml file to Camunda server

param(
    [string]$ServerIP = "109.172.36.204",
    [string]$Username = "root",
    [string]$RemotePath = "/opt/camunda7/server/apache-tomcat-10.1.36/webapps/engine-rest/WEB-INF",
    [string]$BackupPath = "/opt/camunda7/backups",
    [switch]$DryRun,
    [switch]$RestartService,
    [switch]$CreateBackup = $true
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

# Function to execute SSH command
function Invoke-SSHCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    if ($DryRun) {
        Write-Warning "DRY RUN: $Description"
        Write-Warning "    Command: $Command"
        return $true
    }
    
    Write-Info "Executing: $Description"
    
    try {
        $process = Start-Process -FilePath "plink" -ArgumentList @(
            "-batch",
            "$Username@$ServerIP",
            "`"$Command`""
        ) -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Success "Completed: $Description"
            return $true
        } else {
            Write-Error "Error executing: $Description"
            return $false
        }
    } catch {
        Write-Error "SSH command error: $($_.Exception.Message)"
        return $false
    }
}

# Function to create backup
function Create-Backup {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "web.xml.backup.$timestamp"
    
    $createBackupDirCommand = "mkdir -p $BackupPath"
    $backupCommand = "cp $RemotePath/web.xml $BackupPath/$backupFile"
    
    if (-not (Invoke-SSHCommand -Command $createBackupDirCommand -Description "Creating backup directory")) {
        return $false
    }
    
    if (Invoke-SSHCommand -Command $backupCommand -Description "Creating web.xml backup") {
        Write-Success "Backup created: $BackupPath/$backupFile"
        return $true
    }
    
    return $false
}

# Function to deploy CORS file
function Deploy-CorsFile {
    param([string]$FilePath)
    
    $fileName = Split-Path $FilePath -Leaf
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    Write-Info "Sending: $fileName"
    
    if ($DryRun) {
        Write-Warning "DRY RUN: pscp `"$FilePath`" $Username@${ServerIP}:$RemotePath/"
        return $true
    }
    
    try {
        $pscpArgs = @(
            "`"$FilePath`"",
            "$Username@${ServerIP}:$RemotePath/"
        )
        
        Start-Process -FilePath "pscp" -ArgumentList $pscpArgs -Wait -NoNewWindow
        Write-Success "File sent: $fileName"
        return $true
    } catch {
        Write-Error "Error sending $fileName : $($_.Exception.Message)"
        return $false
    }
}

# Function to check Camunda service status
function Get-CamundaStatus {
    $checkCommand = "systemctl is-active camunda7"
    
    if ($DryRun) {
        Write-Warning "DRY RUN: Checking Camunda service status"
        return "active"
    }
    
    try {
        $process = Start-Process -FilePath "plink" -ArgumentList @(
            "-batch",
            "$Username@$ServerIP",
            "`"$checkCommand`""
        ) -Wait -PassThru -NoNewWindow -RedirectStandardOutput "camunda_status.tmp"
        
        if (Test-Path "camunda_status.tmp") {
            $status = Get-Content "camunda_status.tmp" -Raw
            Remove-Item "camunda_status.tmp" -Force -ErrorAction SilentlyContinue
            return $status.Trim()
        }
        
        return "unknown"
    } catch {
        return "error"
    }
}

# Function to restart Camunda service
function Restart-CamundaService {
    Write-Info "Restarting Camunda service..."
    
    $serviceName = "camunda7"
    $restartCommand = "sudo systemctl restart $serviceName"
    
    if (Invoke-SSHCommand -Command $restartCommand -Description "Restarting $serviceName") {
        Write-Info "Waiting 10 seconds for service to restart..."
        Start-Sleep -Seconds 10
        
        $statusCommand = "systemctl is-active $serviceName"
        if (Invoke-SSHCommand -Command $statusCommand -Description "Checking $serviceName status") {
            Write-Success "Service ($serviceName) restarted successfully and is active."
            return $true
        } else {
            Write-Warning "Service ($serviceName) failed to report active status after restart."
            return $false
        }
    }
    
    Write-Error "Could not restart Camunda service. Manual intervention may be required."
    return $false
}

# Function to test XML file
function Test-XmlFile {
    param([string]$FilePath)
    
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($FilePath)
        Write-Success "XML file is valid"
        return $true
    } catch {
        Write-Error "XML file contains errors: $($_.Exception.Message)"
        return $false
    }
}

# Main function
function Main {
    Write-Info "Starting CORS configuration deployment..."
    Write-Info "Server: $ServerIP"
    Write-Info "User: $Username"
    Write-Info "Remote path: $RemotePath"
    Write-Info "Backup path: $BackupPath"
    
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - files will not be sent"
    }
    
    # Check pscp availability
    if (-not (Test-PscpAvailable)) {
        Write-Error "pscp not found! Make sure PuTTY is installed and pscp is available in PATH"
        exit 1
    }
    
    # Find web.xml file in the script's directory
    $scriptDir = $PSScriptRoot
    $webXmlFile = Join-Path $scriptDir "web.xml"
    
    if (-not (Test-Path $webXmlFile)) {
        Write-Error "web.xml file not found in script directory: $scriptDir"
        exit 1
    }
    
    # Test XML file
    if (-not (Test-XmlFile -FilePath $webXmlFile)) {
        Write-Error "Deployment aborted due to XML file errors"
        exit 1
    }
    
    # Create backup if enabled
    if ($CreateBackup) {
        Write-Info "Creating backup of current file..."
        if (-not (Create-Backup)) {
            Write-Warning "Could not create backup, continuing without it"
        }
    }
    
    # Deploy file
    if (-not (Deploy-CorsFile -FilePath $webXmlFile)) {
        Write-Error "Error deploying file"
        exit 1
    }
    
    # Set correct permissions
    $chmodCommand = "chmod 644 $RemotePath/web.xml && chown tomcat:tomcat $RemotePath/web.xml"
    Invoke-SSHCommand -Command $chmodCommand -Description "Setting file permissions"
    
    # Restart Tomcat if specified
    if ($RestartService) {
        Write-Info "Restarting Camunda service to apply changes..."
        
        # Check current status
        $currentStatus = Get-CamundaStatus
        Write-Info "Current Camunda status: $currentStatus"
        
        if ($currentStatus -eq "active") {
            Restart-CamundaService
        } else {
            Write-Warning "Camunda is not active. Manual start may be required."
        }
    } else {
        Write-Warning "Don't forget to restart Camunda service to apply CORS changes!"
        Write-Info "Use -RestartService parameter for automatic restart"
    }
    
    Write-Success "CORS configuration deployment completed successfully!"
    Write-Info "Check Tomcat logs to ensure proper operation"
}

# Help
if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "-h") {
    Write-Host @"
CORS Configuration Deployment Script

DESCRIPTION:
    Automatic deployment of web.xml file to Camunda server with backup creation
    and optional Tomcat restart.

USAGE:
    .\deploy-cors.ps1 [parameters]

PARAMETERS:
    -ServerIP [IP]        Server IP address (default: 109.172.36.204)
    -Username [user]      Username (default: root)
    -RemotePath [path]    Remote path to WEB-INF (default: /opt/camunda7/server/apache-tomcat-10.1.36/webapps/engine-rest/WEB-INF)
    -BackupPath [path]    Backup path (default: /opt/camunda7/backups)
    -DryRun              Test mode (files will not be sent)
    -RestartService      Automatically restart camunda7 service after deployment
    -CreateBackup        Create backup before replacement (default: enabled)
    -help                Show this help

EXAMPLES:
    .\deploy-cors.ps1                                     # Basic deployment with backup
    .\deploy-cors.ps1 -DryRun                            # Test run
    .\deploy-cors.ps1 -RestartService                   # Deploy with Camunda restart
    .\deploy-cors.ps1 -ServerIP "192.168.1.100"         # Different server
    .\deploy-cors.ps1 -CreateBackup:`$false              # Without backup

REQUIREMENTS:
    - PuTTY (pscp and plink) must be installed and available in PATH
    - SSH authentication configured on server
    - web.xml file in current directory

SECURITY:
    - Always creates backup of current file (unless disabled)
    - Validates XML before deployment
    - Sets correct file permissions

RECOVERY:
    To restore from backup:
    cp $BackupPath/web.xml.backup.TIMESTAMP $RemotePath/web.xml
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