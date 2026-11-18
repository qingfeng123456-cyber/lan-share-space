[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ShareDir,
    [string] $LanIP = '127.0.0.1',
    [ValidateRange(1, 65535)] [int] $Port = 3923
)

$ErrorActionPreference = 'Stop'
$share = (Resolve-Path -LiteralPath $ShareDir).ProviderPath
if (-not (Test-Path -LiteralPath $share -PathType Container)) { throw 'ShareDir must be an existing folder.' }
if ($share -match '[\r\n]') { throw 'The shared path cannot contain a line break.' }
$parsedIP = $null
if (-not [System.Net.IPAddress]::TryParse($LanIP, [ref] $parsedIP) -or $parsedIP.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) { throw 'LanIP must be a local IPv4 address.' }
if ($LanIP -ne '127.0.0.1' -and -not (Get-NetIPAddress -AddressFamily IPv4 -IPAddress $LanIP -ErrorAction SilentlyContinue)) { throw 'LanIP must belong to a network interface on this computer.' }

$pythonZip = Join-Path $PSScriptRoot 'python-3.14.10-embed-amd64.zip'
$copyparty = Join-Path $PSScriptRoot 'copyparty-sfx.py'
if (-not (Test-Path -LiteralPath $pythonZip -PathType Leaf)) { throw 'Missing bundled Python archive.' }
if (-not (Test-Path -LiteralPath $copyparty -PathType Leaf)) { throw 'Missing bundled copyparty-sfx.py.' }

$runtime = Join-Path $env:LOCALAPPDATA 'LanShareUI'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$runtime = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $runtime).ProviderPath).TrimEnd([char[]]'\/')

function Assert-RuntimeChild([string] $Path, [string] $ExpectedName, [bool] $MustExist) {
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
    $parent = [System.IO.Path]::GetDirectoryName($full).TrimEnd([char[]]'\/')
    if (-not $parent.Equals($runtime, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not [System.IO.Path]::GetFileName($full).Equals($ExpectedName, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to operate outside the expected runtime directory: $full"
    }
    if (Test-Path -LiteralPath $full) {
        $item = Get-Item -LiteralPath $full -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Refusing to operate on a reparse point: $full" }
        $resolved = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $full).ProviderPath).TrimEnd([char[]]'\/')
        if (-not $resolved.Equals($full, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Unexpected resolved runtime path: $resolved" }
    } elseif ($MustExist) { throw "Expected temporary runtime directory is missing: $full" }
}

$pythonDir = Join-Path $runtime 'python-3.14.10-x64'
$pythonExe = Join-Path $pythonDir 'python.exe'
if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) {
    if (Test-Path -LiteralPath $pythonDir) { throw "Incomplete Python runtime at $pythonDir. Rename this folder and retry." }
    Write-Host '首次启动：正在准备随附的 Python 运行环境，请稍候……'
    $unpackName = 'python-unpack-' + [guid]::NewGuid().ToString('N')
    $unpackDir = Join-Path $runtime $unpackName
    Assert-RuntimeChild $unpackDir $unpackName $false
    Assert-RuntimeChild $pythonDir 'python-3.14.10-x64' $false
    try {
        Expand-Archive -LiteralPath $pythonZip -DestinationPath $unpackDir
        if (-not (Test-Path -LiteralPath (Join-Path $unpackDir 'python.exe') -PathType Leaf)) { throw 'Bundled Python archive does not contain python.exe.' }
        Assert-RuntimeChild $unpackDir $unpackName $true
        Assert-RuntimeChild $pythonDir 'python-3.14.10-x64' $false
        try { [System.IO.Directory]::Move($unpackDir, $pythonDir) }
        catch {
            # Another instance may have finished preparing the same runtime.
            if (-not (Test-Path -LiteralPath $pythonExe -PathType Leaf)) { throw }
        }
    } finally {
        if (Test-Path -LiteralPath $unpackDir) {
            Assert-RuntimeChild $unpackDir $unpackName $true
            Remove-Item -LiteralPath $unpackDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

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
    & $pythonExe $copyparty -c $configPath -i $LanIP -p $Port --no-crt
    $exitCode = $LASTEXITCODE
} finally {
    Remove-Item -LiteralPath $htmlPath, $configPath -Force -ErrorAction SilentlyContinue
}
if ($null -ne $exitCode -and $exitCode -ne 0) { exit $exitCode }
