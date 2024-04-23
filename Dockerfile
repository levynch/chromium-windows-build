# 使用Windows Server Core作为基础镜像
FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

# 设置工作目录
WORKDIR D:\\chromium

# 安装必要的工具
SHELL ["cmd", "/S", "/C"]
RUN powershell -Command \
    $ErrorActionPreference = 'Stop'; \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -OutFile depot_tools.zip -Uri https://storage.googleapis.com/chrome-infra/depot_tools.zip; \
    Expand-Archive depot_tools.zip -DestinationPath D:\\depot_tools; \
    Remove-Item depot_tools.zip -Force;

# 设置环境变量
ENV PATH="D:\\depot_tools;$PATH"
ENV DEPOT_TOOLS_WIN_TOOLCHAIN=0

# 安装Visual Studio
RUN powershell -Command \
    Invoke-WebRequest -OutFile vs_installer.exe -Uri https://aka.ms/vs/17/release/vs_community.exe; \
    Start-Process vs_installer.exe -ArgumentList '--quiet --wait --norestart --nocache \
        --installPath C:\\VisualStudio \
        --add Microsoft.VisualStudio.Workload.NativeDesktop \
        --add Microsoft.VisualStudio.Component.VC.ATLMFC \
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
        --includeRecommended' -Wait; \
    Remove-Item vs_installer.exe -Force

# 安装Debugging Tools
RUN powershell -Command \
    $sdkPath = 'C:\\Program Files (x86)\\Windows Kits\\10\\'; \
    $debugToolsPath = $sdkPath + 'Debuggers\\x64\\dbgsdk.msi'; \
    Start-Process msiexec.exe -ArgumentList '/i', $debugToolsPath, '/quiet', '/norestart' -Wait

# 克隆Chromium源码
RUN fetch chromium --no-history
RUN gclient sync 

# 编译Chromium
# RUN call C:\\depot_tools\\ninja.exe -C out/Default chrome

# 输出 D:\\chromium 文件夹的大小
RUN powershell -Command \
    "Get-ChildItem -Path C:\\chromium -Recurse | Measure-Object -Property Length -Sum | ForEach-Object { 'Directory size: ' + $_.Sum / 1GB + ' GB' }"
