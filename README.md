# 局域网共享空间

一个基于 [copyparty](https://github.com/9001/copyparty) 的中文网页文件共享界面。启动后，电脑和手机可以通过浏览器浏览共享目录，并进行上传、下载、重命名和删除。文件留在运行服务的电脑上，传输速度取决于网络和磁盘。

## 使用前请了解

- 本项目提供界面和启动脚本，文件服务由 **copyparty** 提供；需要单独下载其 Windows 可执行文件。本界面针对 **copyparty v1.20.26** 制作，其他版本可能不兼容。
- 此配置允许所有能够访问服务的设备直接查看、上传、修改和删除共享目录中的文件，不需要登录。请只选择适合共享的专用文件夹，并保留重要文件的独立备份。
- 示例通过 **HTTP** 访问，传输内容未加密。请仅在可信网络使用，不要配置路由器端口映射或把服务暴露到公网。
- 电脑必须保持开机、服务运行且不休眠，其他设备才能访问。

## Windows 快速开始

1. 下载本项目到本地。从 [copyparty v1.20.26 官方发布页](https://github.com/9001/copyparty/releases/tag/v1.20.26) 下载 Windows 可执行文件 `copyparty.exe`，保存到本机可信位置。
2. 新建一个空的专用共享文件夹。共享文件夹必须已存在，且运行服务的 Windows 账户须有相应读写权限。
3. 在本项目目录打开 PowerShell。将下面两个路径替换为自己的实际路径，先在本机启动：

   ```powershell
   .\start.ps1 -ShareDir 'C:\Share' -CopypartyPath 'C:\Tools\copyparty.exe'
   ```

   如果系统阻止脚本运行，可在当前 PowerShell 进程中临时放开脚本执行限制，然后重新运行上面的命令：

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

4. 在这台电脑的浏览器中打开 [http://127.0.0.1:3923/](http://127.0.0.1:3923/)。看到共享页面后，用临时测试文件验证上传、下载和删除。

默认只监听本机，其他设备无法连接。如果确认要在可信局域网内共享，按 `Ctrl+C` 停止服务，查询本机连接局域网的 IPv4 地址，再把下面的 `本机局域网IPv4` 替换为实际地址后启动：

```powershell
.\start.ps1 -ShareDir 'C:\Share' -CopypartyPath 'C:\Tools\copyparty.exe' -LanIP '本机局域网IPv4'
```

在同一局域网的其他设备上，打开 `http://本机局域网IPv4:3923/`。可在 Windows 的网络连接属性中查看 IPv4 地址。自定义端口可添加 `-Port 端口号`。关闭服务窗口或按 `Ctrl+C` 可停止服务。

## 使用与排查

- **上传**：进入目标文件夹，选择“上传文件”，再选择文件。上传后刷新列表并确认文件出现在共享目录。
- **管理文件**：选中文件后使用对应的重命名或删除操作；删除会影响共享目录中的真实文件。
- **本机可以打开，其他设备打不开**：确认地址为运行服务的电脑当前局域网 IPv4、指定了 `-LanIP`、两台设备在互通的网络中；检查 Windows 防火墙是否允许所用端口在专用网络入站。访客网络或无线设备隔离也可能阻止连接。不要为此关闭整个防火墙。
- **无法上传或删除**：检查共享文件夹自身的 Windows 权限，以及运行服务的账户是否可写入该目录。
- **页面显示异常**：确认使用了指定的 copyparty 版本，重新启动服务并刷新浏览器。

## 项目文件

- `start.ps1`：读取界面文件并启动本机 copyparty。
- `lan-base.html`、`redesign2.css`、`redesign2.js`：界面定制文件。

本项目不应包含个人共享文件、访问凭据、运行日志或本机配置。`.gitignore` 只提供基础保护，公开提交前仍应检查暂存内容。

## 上游与许可

文件服务由 [copyparty](https://github.com/9001/copyparty) 提供，其上游主项目采用 [MIT License](https://github.com/9001/copyparty/blob/hovudstraum/LICENSE)。有关上游软件及其附带组件的许可，请查阅上游随发行版提供的许可文件。

本仓库的界面定制代码和启动脚本以 [MIT License](LICENSE) 发布。
