param(
  [ValidateSet('sync','pull','push','status')]
  [string]$Action = 'sync',
  [string]$Message = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-Git([string[]]$Arguments) {
  & git -C $repoRoot @Arguments
  if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed" }
}

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
  throw "Not a Git repository: $repoRoot"
}

if ($Action -eq 'status') {
  Invoke-Git @('status','--short','--branch')
  exit 0
}

if ($Action -in @('sync','pull')) {
  Invoke-Git @('pull','--ff-only')
  if ($Action -eq 'pull') { exit 0 }
}

$changes = (& git -C $repoRoot status --porcelain) | Out-String
if ($LASTEXITCODE -ne 0) { throw 'git status failed' }
if ([string]::IsNullOrWhiteSpace($changes)) {
  Write-Host '[sync] No changes to commit.'
  exit 0
}

Invoke-Git @('add','-A')
$blocked = (& git -C $repoRoot diff --cached --name-only) | Where-Object {
  $_ -match '^(memory|projects|project-data)/' -or $_ -match '\.project\.md$'
}
if ($blocked) {
  & git -C $repoRoot restore --staged -- @blocked
  throw "Project data is blocked from cloud sync: $($blocked -join ', ')"
}
if ([string]::IsNullOrWhiteSpace($Message)) {
  $Message = 'sync: update skills and memory ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')
}
Invoke-Git @('commit','-m',$Message)
Invoke-Git @('push')
