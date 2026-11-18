[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Pause-AndExit([int] $Code) {
    Write-Host ''
    Read-Host '按 Enter 键关闭窗口' | Out-Null
    exit $Code
}

try {
    $pythonZip = Join-Path $PSScriptRoot 'python-3.14.10-embed-amd64.zip'
    $copyparty = Join-Path $PSScriptRoot 'copyparty-sfx.py'
    $runner = Join-Path $PSScriptRoot 'start.ps1'
    if (-not (Test-Path -LiteralPath $pythonZip -PathType Leaf)) { throw '找不到随程序附带的 Python 运行环境，请保持程序文件完整，并先解压整个文件夹。' }
    if (-not (Test-Path -LiteralPath $copyparty -PathType Leaf)) { throw '找不到 copyparty-sfx.py，请保持程序文件完整，并先解压整个文件夹。' }
    if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw '找不到 start.ps1，请保持程序文件完整，并先解压整个文件夹。' }

    Write-Host '============================================'
    Write-Host '              局域网共享空间'
    Write-Host '============================================'
    Write-Host ''
    Write-Host '请选择要共享的文件夹。'
    $defaultShare = Join-Path $PSScriptRoot '共享文件'
    Write-Host "直接按 Enter 使用：$defaultShare"
    $share = Read-Host '文件夹完整路径'
    if ([string]::IsNullOrWhiteSpace($share)) { $share = $defaultShare }
    else { $share = $share.Trim().Trim('"') }
    if (-not [System.IO.Path]::IsPathRooted($share)) { throw '请输入完整路径，例如 D:\共享文件。' }
    if (-not (Test-Path -LiteralPath $share -PathType Container)) {
        if (Test-Path -LiteralPath $share) { throw '该路径是一个文件，请选择文件夹。' }
        Write-Host "文件夹不存在：$share"
        $create = Read-Host '输入 Y 创建这个文件夹；其他输入退出'
        if ($create -notmatch '^[Yy]$') { Write-Host '已取消。'; Pause-AndExit 0 }
        New-Item -ItemType Directory -Path $share -Force | Out-Null
    }
    $share = (Resolve-Path -LiteralPath $share).ProviderPath

    Write-Host ''
    Write-Host '访问范围：'
    Write-Host '  1. 仅本机（默认，适合先测试）'
    Write-Host '  2. 局域网（同一网络内可以连接的设备均可访问）'
    $mode = Read-Host '请选择 1 或 2，直接按 Enter 选 1'
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = '1' }
    if ($mode -eq '1') { $ip = '127.0.0.1' }
    elseif ($mode -eq '2') {
        $addresses = @(Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -ErrorAction Stop | Where-Object {
            $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*'
        } | Sort-Object InterfaceIndex, IPAddress)
        if ($addresses.Count -eq 0) { throw '没有找到可用的局域网 IPv4 地址。请检查 Wi-Fi 或网线后重试。' }
        Write-Host ''
        Write-Host '请选择连接局域网的网络地址：'
        for ($i = 0; $i -lt $addresses.Count; $i++) {
            Write-Host ('  {0}. {1}  ({2})' -f ($i + 1), $addresses[$i].IPAddress, $addresses[$i].InterfaceAlias)
        }
        $choice = Read-Host '输入序号'
        $number = 0
        if (-not [int]::TryParse($choice, [ref] $number) -or $number -lt 1 -or $number -gt $addresses.Count) { throw '网络地址序号无效，请重新运行并选择列表中的序号。' }
        $ip = $addresses[$number - 1].IPAddress
        Write-Host ''
        Write-Host '注意：能连接此网址的任何人都可以查看、上传、修改和删除共享目录中的文件。'
        Write-Host '连接使用 HTTP，传输内容不加密；请只在可信局域网使用。'
    }
    else { throw '选择无效，请重新运行并输入 1 或 2。' }

    $port = 3923
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Parse($ip), $port)
    try { $listener.Start() }
    catch { throw "地址 ${ip}:${port} 已被占用，或无法监听。请先停止占用该地址的程序。" }
    finally { $listener.Stop() }

    $url = "http://${ip}:${port}/"
    Write-Host ''
    Write-Host "共享文件夹：$share"
    Write-Host "浏览器地址：$url"
    Write-Host '正在启动；请保持此窗口打开。按 Ctrl+C 或关闭窗口可停止服务。'
    Write-Host '其他设备无法访问时，请检查网络隔离及 Windows 防火墙。'
    # Wait for the listener before opening the browser. A failed start does not open a misleading page.
    $browserJob = Start-Job -ArgumentList $ip, $port, $url -ScriptBlock {
        param($targetIp, $targetPort, $targetUrl)
        for ($n = 0; $n -lt 240; $n++) {
            Start-Sleep -Milliseconds 500
            $client = New-Object System.Net.Sockets.TcpClient
            try {
                $client.Connect($targetIp, $targetPort)
                $client.Close()
                Start-Process $targetUrl
                break
            } catch { $client.Close() }
        }
    }
    try {
        & $runner -ShareDir $share -LanIP $ip -Port $port
        if ($LASTEXITCODE -ne 0) { throw "服务已停止，退出代码：$LASTEXITCODE" }
    } finally {
        Stop-Job -Job $browserJob -ErrorAction SilentlyContinue
        Remove-Job -Job $browserJob -Force -ErrorAction SilentlyContinue
    }
    Write-Host '共享服务已停止。'
    Pause-AndExit 0
} catch {
    Write-Host ''
    Write-Host ('启动失败：' + $_.Exception.Message) -ForegroundColor Red
    Pause-AndExit 1
}
