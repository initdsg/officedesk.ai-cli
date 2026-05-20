#Requires -Version 5.1
<#
.SYNOPSIS
    OfficeDesk AI — Windows Installer
.DESCRIPTION
    Usage: irm https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install.ps1 | iex
           & ([scriptblock]::Create((irm https://raw.githubusercontent.com/initdsg/officedesk.ai-cli/main/install.ps1))) plugin-gmail plugin-jira
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Products = @('officedesk')
)

$ErrorActionPreference = 'Stop'

# ──────────────────────────────────────────────────────────────────────
$InstallDir = "$env:USERPROFILE\.officedesk\bin"
$GithubRepo = "initdsg/officedesk.ai-cli"
$GithubApi  = "https://api.github.com/repos/$GithubRepo/releases?per_page=50"
$GithubDl   = "https://github.com/$GithubRepo/releases/download"

# Product registry: name => (tag_prefix, binary_name)
$ProductRegistry = [ordered]@{
    'officedesk'             = 'officedesk-v',             'officedesk'
    'plugin-gmail'           = 'plugin-gmail-v',           'officedesk-plugin-gmail'
    'plugin-google-calendar' = 'plugin-google-calendar-v', 'officedesk-plugin-google-calendar'
    'plugin-google-sheets'   = 'plugin-google-sheets-v',   'officedesk-plugin-google-sheets'
    'plugin-jira'            = 'plugin-jira-v',            'officedesk-plugin-jira'
    'plugin-email'           = 'plugin-email-v',           'officedesk-plugin-email'
    'plugin-odoo'            = 'plugin-odoo-v',            'officedesk-plugin-odoo'
    'plugin-xero'            = 'plugin-xero-v',            'officedesk-plugin-xero'
    'plugin-whatsapp'        = 'plugin-whatsapp-v',        'officedesk-plugin-whatsapp'
}

# ── Helpers ───────────────────────────────────────────────────────────
function Write-Info    ($msg) { Write-Host $msg -ForegroundColor DarkGray }
function Write-Success ($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Err     ($msg) { Write-Host "error: $msg" -ForegroundColor Red; exit 1 }

function Get-LatestTag ($Releases, $Prefix) {
    foreach ($r in $Releases) {
        if ($r.tag_name -like "$Prefix*") { return $r.tag_name }
    }
    return $null
}

# ── Download & install one product ───────────────────────────────────
function Install-Product ($Name, $Releases) {
    $entry = $ProductRegistry[$Name]
    $tagPrefix, $binaryName = $entry

    $tag = Get-LatestTag -Releases $Releases -Prefix $tagPrefix
    if (-not $tag) { Write-Err "No release found for '$Name'" }

    $asset = "$binaryName.exe"
    $dest  = Join-Path $InstallDir $asset
    $url   = "$GithubDl/$tag/$asset"

    Write-Info "Installing $Name ($tag)..."
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    Write-Success "Installed $dest"
}

# ── PATH setup ────────────────────────────────────────────────────────
function Add-ToPath {
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($current -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$InstallDir;$current", 'User')
        $env:PATH = "$InstallDir;$env:PATH"
        Write-Info "Added $InstallDir to PATH (user scope)"
        return $true
    }
    return $false
}

# ── Main ──────────────────────────────────────────────────────────────
# Validate all products up front
foreach ($name in $Products) {
    if (-not $ProductRegistry.Contains($name)) {
        Write-Err "Unknown product '$name'`n       available: $($ProductRegistry.Keys -join ', ')"
    }
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Info "Fetching releases..."
try {
    $releases = Invoke-RestMethod -Uri $GithubApi -UseBasicParsing
} catch {
    Write-Err "Failed to reach GitHub API. Check your internet connection."
}

foreach ($name in $Products) {
    Install-Product -Name $name -Releases $releases
}

$addedToPath = Add-ToPath

Write-Host ""
Write-Success "Done!"
if ($addedToPath) {
    Write-Info "Restart your terminal for the PATH change to take effect."
}
