param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Folder resolution
$ToolDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ToolDir "..\..")

$VenvDir  = Join-Path $ToolDir ".venv"
$ReqFile  = Join-Path $ToolDir "requirements.txt"
$CfgFile  = Join-Path $ToolDir ".sqlfluff"

$Python   = "python"
$Pip      = Join-Path $VenvDir "Scripts\pip.exe"
$Sqlfluff = Join-Path $VenvDir "Scripts\sqlfluff.exe"

# ✅ Static plugin root (no parameter)
$CustomRulesRoot = Join-Path $ToolDir "custom-rules"
$CustomRulesPyProject = Join-Path $CustomRulesRoot "pyproject.toml"

function Fail($msg) {
    throw "[sqlfluff setup] $msg"
}

function Assert-FileExists($path, $name) {
    if (-not (Test-Path $path)) { Fail "$name not found: $path" }
}

function Assert-Python {
    $cmd = Get-Command $Python -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Fail "Python not found on PATH. Install Python 3.x and ensure 'python --version' works."
    }

    $ver = & $Python --version 2>&1
    Write-Host "Found: $ver"
}

function Remove-VenvIfNeeded {
    if ($Force -and (Test-Path $VenvDir)) {
        Write-Host "Removing existing venv: $VenvDir"
        Remove-Item -Recurse -Force $VenvDir
    }
}

function Ensure-Venv {
    if (-not (Test-Path $VenvDir)) {
        Write-Host "Creating venv in: $VenvDir"
        & $Python -m venv $VenvDir
    } else {
        Write-Host "Venv already exists: $VenvDir"
    }
}

function Ensure-Pip {
    if (-not (Test-Path $Pip)) {
        Fail "pip not found in venv. Venv creation may have failed."
    }

    Write-Host "Upgrading pip + setuptools + wheel..."
    & $Pip install --upgrade pip setuptools wheel | Out-Host
}

function Install-Reqs {
    Assert-FileExists $ReqFile "requirements.txt"

    Write-Host "Installing requirements from: $ReqFile"
    & $Pip install -r $ReqFile | Out-Host
}

function Verify-Sqlfluff {
    if (-not (Test-Path $Sqlfluff)) {
        Fail "sqlfluff.exe not found after install. Check requirements.txt and pip output."
    }

    Write-Host "SQLFluff version:"
    & $Sqlfluff --version | Out-Host

    # Optional: quick config sanity check
    if (Test-Path $CfgFile) {
        Write-Host "Config file found: $CfgFile"
    } else {
        Write-Host "WARNING: .sqlfluff config not found at $CfgFile (you can add it later)."
    }
}

function Install-CustomRulesPlugin {
    if (-not (Test-Path $CustomRulesRoot)) {
        Fail "Custom rules folder not found: $CustomRulesRoot"
    }
    Assert-FileExists $CustomRulesPyProject "Custom rules pyproject.toml"

    Write-Host "Installing custom SQLFluff rules plugin (editable) from: $CustomRulesRoot"
    Push-Location $CustomRulesRoot
    try {
        & $Pip install -e . | Out-Host
    } finally {
        Pop-Location
    }

    Write-Host "Custom rules plugin loaded."
}

function Ensure-LocalGitIgnore {
    $gitDir = Join-Path $RepoRoot ".git"
    if (-not (Test-Path $gitDir)) {
        Write-Host "No .git folder found. Skipping local git exclude setup."
        return
    }

    $excludeFile = Join-Path $gitDir "info\exclude"

    if (-not (Test-Path $excludeFile)) {
        Write-Host "Creating git exclude file: $excludeFile"
        New-Item -ItemType File -Path $excludeFile | Out-Null
    }

    $entry = "sql-lint-tool/"

    $content = Get-Content $excludeFile -ErrorAction SilentlyContinue
    if ($content -notcontains $entry) {
        Add-Content $excludeFile "`n# SQL lint tool (local)`n$entry"
        Write-Host "Added 'sql-lint-tool/' to .git/info/exclude"
    } else {
        Write-Host "'sql-lint-tool/' already present in git exclude."
    }
}


Write-Host "=== SQLFluff Setup ==="
Write-Host "Tool directory : $ToolDir"
Write-Host "Repo root      : $RepoRoot"
Write-Host ""

Assert-Python
Remove-VenvIfNeeded
Ensure-Venv
Ensure-Pip
Install-Reqs
Verify-Sqlfluff

Install-CustomRulesPlugin

Ensure-LocalGitIgnore

Write-Host "✅ Setup completed."
