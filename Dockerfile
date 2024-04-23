# escape=`

# Use the latest Windows Server Core 2022 image.
FROM mcr.microsoft.com/windows/server:10.0.20348.2340-amd64

# Set PowerShell as the default shell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Download Visual Studio Build Tools
RUN Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_buildtools.exe" -OutFile "vs_buildtools.exe"

# Install Visual Studio Build Tools
RUN Start-Process -FilePath "vs_buildtools.exe" -ArgumentList '--quiet', '--norestart', '--nocache', `
    '--installPath', "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools", `
    '--add Microsoft.VisualStudio.Workload.NativeDesktop', `
    '--add Microsoft.VisualStudio.Component.VC.ATLMFC' -Wait -NoNewWindow; `
    Remove-Item -Path "vs_buildtools.exe" -Force

# Set work directory
WORKDIR C:/chromium

# Install necessary tools
RUN Invoke-WebRequest -Uri 'https://storage.googleapis.com/chrome-infra/depot_tools.zip' -OutFile 'depot_tools.zip'; `
    Expand-Archive -Path 'depot_tools.zip' -DestinationPath 'C:/depot_tools'; `
    Remove-Item 'depot_tools.zip' -Force

# Set environment variables
ENV PATH="C:\depot_tools;$PATH"
ENV DEPOT_TOOLS_WIN_TOOLCHAIN=0

# Set work directory
WORKDIR C:/sdk

# Download Windows SDK installer
ADD "https://download.microsoft.com/download/d/9/6/d968e973-c27d-4d17-ae51-fc7a98d9b0d3/windowssdk/winsdksetup.exe" C:/sdk/winsdksetup.exe

# Run installer
RUN Start-Process -FilePath 'C:/sdk/winsdksetup.exe' -ArgumentList '/quiet', '/norestart', `
    '/features', '+OptionId.WindowsSoftwareDevelopmentKit', '/features', '+OptionId.Debugger' -Wait -NoNewWindow; `
    Remove-Item 'C:/sdk/winsdksetup.exe' -Force

# Set work directory
WORKDIR C:/chromium

# Clone Chromium source code
RUN & 'fetch' 'chromium' '--no-history'
RUN & 'gclient' 'sync'

# Compile Chromium (commented out)
# RUN & 'C:/depot_tools/ninja.exe' '-C' 'out/Default' 'chrome'

# Output the size of the C:/chromium folder
RUN Get-ChildItem -Path 'C:/chromium' -Recurse | Measure-Object -Property Length -Sum | ForEach-Object { "Directory size: $($_.Sum / 1GB) GB" }
