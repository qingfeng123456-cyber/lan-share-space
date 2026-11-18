[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ShareDir,
    [Parameter(Mandatory = $true)] [string] $CopypartyPath,
    [string] $LanIP = '127.0.0.1',
    [ValidateRange(1, 65535)] [int] $Port = 3923
)

$ErrorActionPreference = 'Stop'
$share = (Resolve-Path -LiteralPath $ShareDir).ProviderPath
$exe = (Resolve-Path -LiteralPath $CopypartyPath).ProviderPath
if (-not (Test-Path -LiteralPath $share -PathType Container)) { throw 'ShareDir must be an existing folder.' }
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'CopypartyPath must be an existing executable.' }
if ($share -match '[\r\n]') { throw 'The shared path cannot contain a line break.' }
$parsedIP = $null
if (-not [System.Net.IPAddress]::TryParse($LanIP, [ref] $parsedIP) -or $parsedIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) { throw 'LanIP must be a local IPv4 address.' }
if ($LanIP -ne '127.0.0.1' -and -not (Get-NetIPAddress -AddressFamily IPv4 -IPAddress $LanIP -ErrorAction SilentlyContinue)) { throw 'LanIP must belong to a network interface on this computer.' }

$runtime = Join-Path $env:LOCALAPPDATA 'LanShareUI'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$htmlPath = Join-Path $runtime ("ui-{0}.html" -f $PID)
$configPath = Join-Path $runtime ("config-{0}.conf" -f $PID)
$base = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'lan-base.html')
$css = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'redesign2.css')
$js = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'redesign2.js')
$utf8 = New-Object System.Text.UTF8Encoding($false)
$html = $base + "`n<style>`n" + $css + "`n</style>`n" + $js
[System.IO.File]::WriteAllText($htmlPath, $html, $utf8)
$headPath = $htmlPath.Replace('\', '/')
$config = "[global]`n  lang: chi`n  html-head: %@${headPath}`n`n[/]`n  ${share}`n  accs:`n    rwmd: *`n"
[System.IO.File]::WriteAllText($configPath, $config, $utf8)
Write-Host "Address: http://${LanIP}:${Port}/"
Write-Host 'Anyone who can connect has full read, upload, modify and delete access.'
Write-Host 'HTTP is unencrypted. Use only on a trusted network. Press Ctrl+C to stop.'
try {
    & $exe -c $configPath -i $LanIP -p $Port --no-crt
    $exitCode = $LASTEXITCODE
} finally {
    Remove-Item -LiteralPath $htmlPath, $configPath -Force -ErrorAction SilentlyContinue
}
if ($null -ne $exitCode -and $exitCode -ne 0) { exit $exitCode }
