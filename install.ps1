# One-line install (PowerShell):  irm https://raw.githubusercontent.com/tleguede-works/Forge/main/install.ps1 | iex
# With options: & ([scriptblock]::Create((irm <url>))) --target claude
$ErrorActionPreference = "Stop"
$repo = if ($env:FORGE_REPO) { $env:FORGE_REPO } else { "tleguede-works/Forge" }
$ref  = if ($env:FORGE_REF)  { $env:FORGE_REF }  else { "main" }
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if (-not $py) { throw "forge-install: Python 3.9+ is required" }
if ($env:FORGE_SRC) { $src = $env:FORGE_SRC }
else {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("forge-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  $zip = Join-Path $tmp "forge.zip"
  Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/$ref.zip" -OutFile $zip
  Expand-Archive $zip -DestinationPath $tmp
  $src = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName
}
& $py.Source (Join-Path $src "scripts\install.py") --src $src @args
$bin = Join-Path $env:USERPROFILE ".forge\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$bin*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User")
  Write-Host "forge-install: added $bin to your user PATH. Open a new terminal."
}
