# escape=`

# Use the latest Windows Server Core 2022 image.
FROM mcr.microsoft.com/windows/servercore:ltsc2022


# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

RUN `
    curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe `
    `
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" `
        --add Microsoft.VisualStudio.Workload.NativeDesktop  `
        --add Microsoft.VisualStudio.Component.VC.ATLMFC `
        --includeRecommended `
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) `
    `
    # Cleanup
    && del /q vs_buildtools.exe

# 设置工作目录
WORKDIR C:\chromium

# 切换到 PowerShell
SHELL ["powershell", "-Command"]
# 安装必要的工具
RUN $ErrorActionPreference = 'Stop'; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -OutFile depot_tools.zip -Uri https://storage.googleapis.com/chrome-infra/depot_tools.zip; `
    Expand-Archive depot_tools.zip -DestinationPath C:\\depot_tools; `
    Remove-Item depot_tools.zip -Force;

# 设置环境变量
ENV PATH="C:\depot_tools;$PATH"
ENV DEPOT_TOOLS_WIN_TOOLCHAIN=0


# 设置工作目录
WORKDIR /sdk

SHELL ["cmd", "/S", "/C"]
# 下载 Windows SDK 安装程序
ADD "https://download.microsoft.com/download/d/9/6/d968e973-c27d-4d17-ae51-fc7a98d9b0d3/windowssdk/winsdksetup.exe" C:\sdk\winsdksetup.exe

# 运行安装程序
# 注意：这里的参数 /features +xxx 可能需要根据实际需要调整，以安装特定的组件
RUN start /w C:\sdk\winsdksetup.exe /quiet /norestart /features +OptionId.WindowsSoftwareDevelopmentKit /features +OptionId.Debugger
# 清理安装文件
RUN del C:\sdk\winsdksetup.exe


# 设置工作目录
WORKDIR C:\chromium

# 克隆Chromium源码
SHELL ["cmd", "/S", "/C"]
ENV PATH="C:\depot_tools;$PATH"
ENV DEPOT_TOOLS_WIN_TOOLCHAIN=0
RUN fetch chromium --no-history
RUN gclient sync 

# 编译Chromium
# RUN call C:\depot_tools\ninja.exe -C out/Default chrome

# 输出 C:\\chromium 文件夹的大小
SHELL ["powershell", "-Command"]
RUN "Get-ChildItem -Path C:\chromium -Recurse | Measure-Object -Property Length -Sum | ForEach-Object { 'Directory size: ' + $_.Sum / 1GB + ' GB' }"
