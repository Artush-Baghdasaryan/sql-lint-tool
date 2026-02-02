param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("lint", "fix")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Target
)

$ErrorActionPreference = "Stop"

# Resolve paths
$ToolDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Resolve-Path (Join-Path $ToolDir "..\..")
$sqlfluff  = Join-Path $ToolDir ".venv\Scripts\sqlfluff.exe"
$config    = Join-Path $ToolDir ".sqlfluff"

if (-not (Test-Path $sqlfluff)) {
    throw "SQLFluff not found. Run tools/sqlfluff/setup.ps1 first."
}

# Determine what to lint/fix
if ([string]::IsNullOrWhiteSpace($Target)) {
    Write-Host "No target provided → running on whole repository..."
    $ResolvedTarget = $RepoRoot
}
else {
    # If Rider passes absolute path, use it.
    # If relative path, resolve against repo root.
    if (Test-Path $Target) {
        $ResolvedTarget = Resolve-Path $Target
    }
    else {
        $Candidate = Join-Path $RepoRoot $Target
        if (-not (Test-Path $Candidate)) {
            throw "Target path not found: $Target"
        }
        $ResolvedTarget = Resolve-Path $Candidate
    }
}

Write-Host "SQLFluff $Action on: $ResolvedTarget"
& $sqlfluff $Action $ResolvedTarget --config $config
exit $LASTEXITCODE
