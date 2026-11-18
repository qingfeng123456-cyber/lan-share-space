# 上游来源与校验

本仓库中的上游文件均为原样保存，界面和启动脚本是单独的文件。以下 SHA-256 值用于核对完整性。

## copyparty v1.20.26

- 官方项目：[9001/copyparty](https://github.com/9001/copyparty)
- 官方发行页：[v1.20.26](https://github.com/9001/copyparty/releases/tag/v1.20.26)
- `copyparty-sfx.py`：[官方发行文件](https://github.com/9001/copyparty/releases/download/v1.20.26/copyparty-sfx.py)；SHA-256：`8f9a0def8a9c15252a06395781ec083372043b60caa80fb33c3d6dafa7f1b40a`
- `copyparty-1.20.26-source.zip`：[GitHub 上游 v1.20.26 标签的源码快照](https://github.com/9001/copyparty/archive/refs/tags/v1.20.26.zip)；本仓库所存文件的 SHA-256：`c42c1cea0dedefddb7e985ab1d47161d1969d247d194ca01b8b27e53c44720d7`
- 上游项目本体采用 MIT 许可，原文见 `COPYPARTY-LICENSE.txt`；上游 SFX 内附组件的版权和许可由 `copyparty-sfx.py --license` 列出，留存于 `COPYPARTY-THIRD-PARTY-LICENSES.txt`。

## Python 3.14.10 Windows 64 位便携包

- [Python 官方发行说明](https://www.python.org/downloads/release/python-31410/)
- `python-3.14.10-embed-amd64.zip`：[官方嵌入式发行包](https://www.python.org/ftp/python/3.14.10/python-3.14.10-embed-amd64.zip)；SHA-256：`90905e64a840557d8c1bc4f5b74db3d7ee85e3ffb217611cac1c7813acea4159`
- 原包中的 `LICENSE.txt` 保存在 `PYTHON-LICENSE.txt`；Python 上游许可证及第三方声明见 `PYTHON-THIRD-PARTY-LICENSES.rst`，对应 [Python v3.14.10 原文件](https://github.com/python/cpython/blob/v3.14.10/Doc/license.rst)。

以上上游组件和其附带组件适用各自许可证；仓库根目录的 `LICENSE` 仅说明本项目界面定制和启动脚本的许可。
