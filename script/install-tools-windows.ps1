<#
.SYNOPSIS
Installs Windows x64 prerequisites using WinGet, rustup, and npm.
.DESCRIPTION
Uses the winget community source and accepts package/source agreements.
Some installers require UAC. Does not request a reboot or replace persisted PATH.
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File script/install-tools-windows.ps1
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File script/install-tools-windows.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$Help, [switch]$SkipBuildTools)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ($Help) { Get-Help $PSCommandPath -Detailed; return }
if (-not $WhatIfPreference -and $env:OS -ne 'Windows_NT') {
    throw 'Run this installer in native Windows PowerShell. For WSL use install-tools-linux.sh.'
}

$packages = @(
    'Neovim.Neovim', 'Git.Git', 'cURL.cURL', 'sharkdp.fd',
    'BurntSushi.ripgrep.MSVC', 'junegunn.fzf', 'tree-sitter.tree-sitter-cli',
    'OpenJS.NodeJS.LTS', 'Rustlang.Rustup', 'LLVM.LLVM'
)
if (-not $SkipBuildTools) { $packages += 'Microsoft.VisualStudio.2022.BuildTools' }

# Preview must work without probing or running any external tools.
if ($WhatIfPreference) {
    foreach ($id in $packages) {
        [void]$PSCmdlet.ShouldProcess($id, 'winget install --exact --source winget (latest available; accepts agreements)')
    }
    if (-not $SkipBuildTools) { [void]$PSCmdlet.ShouldProcess('Visual Studio Build Tools', 'Verify or add the C++ workload') }
    [void]$PSCmdlet.ShouldProcess('Current PowerShell PATH', 'Refresh installed tool paths')
    [void]$PSCmdlet.ShouldProcess('Rust and Pyright', 'Update stable, add rust-analyzer/rustfmt, npm install --global pyright')
    [void]$PSCmdlet.ShouldProcess('Windows prerequisites', 'Run check-tools-windows.ps1')
    return
}
if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw 'winget.exe is missing. Install/update Microsoft App Installer: https://aka.ms/getwinget'
}

function Invoke-Tool([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}
function Update-ToolPath {
    # Preserve inherited custom directories while picking up installer PATH updates.
    $parts = @(
        [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'Machine') + ''),
        [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'User') + ''),
        $env:PATH
    )
    if ($env:USERPROFILE) { $parts += (Join-Path $env:USERPROFILE '.cargo\bin') }
    if ($env:APPDATA) { $parts += (Join-Path $env:APPDATA 'npm') }
    if ($env:LOCALAPPDATA) { $parts += (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links') }
    if ($env:ProgramFiles) {
        $parts += (Join-Path $env:ProgramFiles 'LLVM\bin')
        $parts += (Join-Path $env:ProgramFiles 'WinGet\Links')
    }
    $seen = @{}
    $paths = @()
    foreach ($part in $parts) {
        foreach ($entry in ($part -split ';')) {
            if ($entry -and -not $seen.ContainsKey($entry)) {
                $seen[$entry] = $true
                $paths += $entry
            }
        }
    }
    $env:PATH = $paths -join ';'
}

function Ensure-CppWorkload {
    $installerRoot = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer'
    $vswhere = Join-Path $installerRoot 'vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        throw 'Visual Studio Installer/vswhere is unavailable. Complete any pending installation/reboot, then rerun.'
    }
    $component = 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
    $cppPath = & $vswhere -latest -products '*' -requires $component -property installationPath
    if ($LASTEXITCODE -ne 0) { throw "vswhere failed with exit code $LASTEXITCODE" }
    if ($cppPath) { return }
    # WinGet upgrades do not add workloads to an existing VS installation.
    $buildPath = & $vswhere -latest -products Microsoft.VisualStudio.Product.BuildTools -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $buildPath) { throw 'Build Tools installation was not found after winget completed.' }
    $setup = Join-Path $installerRoot 'setup.exe'
    $quotedPath = '"' + ([string]($buildPath | Select-Object -Last 1)) + '"'
    $process = Start-Process -FilePath $setup -ArgumentList @('modify', '--installPath', $quotedPath,
        '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended', '--passive', '--norestart') -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Visual Studio workload modification failed with exit code $($process.ExitCode)" }
    $cppPath = & $vswhere -latest -products '*' -requires $component -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $cppPath) { throw 'C++ compiler component is still missing after modifying Build Tools.' }
}

foreach ($id in $packages) {
    if (-not $PSCmdlet.ShouldProcess($id, 'Install or upgrade with winget')) { return }
    $arguments = @('install', '--id', $id, '--exact', '--source', 'winget',
        '--architecture', 'x64', '--silent', '--disable-interactivity',
        '--accept-package-agreements', '--accept-source-agreements')
    if ($id -eq 'Microsoft.VisualStudio.2022.BuildTools') {
        $arguments += @('--override', '--wait --passive --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
    }
    & winget.exe @arguments
    $code = $LASTEXITCODE
    $unsignedCode = [long]$code -band 4294967295L
    # WinGet can report an already current package as UPDATE_NOT_APPLICABLE.
    # This alone is not proof of a working tool: the checker below is required.
    if ($code -eq -1978334967 -or $code -eq -1978334966) {
        throw "winget requires a Windows restart for $id (exit $code). Restart Windows and rerun this script."
    }
    if ($code -ne 0 -and $unsignedCode -ne 2316632107L -and $unsignedCode -ne 2316632161L) {
        throw "winget failed for $id with exit code $code"
    }
}
if (-not $SkipBuildTools) {
    if (-not $PSCmdlet.ShouldProcess('Visual Studio Build Tools', 'Verify or add the C++ workload')) { return }
    Ensure-CppWorkload
}
if (-not $PSCmdlet.ShouldProcess('Current PowerShell PATH', 'Refresh installed tool paths')) { return }
Update-ToolPath
if (-not $PSCmdlet.ShouldProcess('Rust and Pyright', 'Install language tools')) { return }
Invoke-Tool 'rustup.exe' @('update', 'stable')
$hasActiveToolchain = $false
try {
    $null = & rustup.exe show active-toolchain 2>&1
    $hasActiveToolchain = $LASTEXITCODE -eq 0
} catch { $hasActiveToolchain = $false }
if (-not $hasActiveToolchain) { Invoke-Tool 'rustup.exe' @('default', 'stable') }
Invoke-Tool 'rustup.exe' @('component', 'add', 'rust-analyzer', 'rustfmt')
Invoke-Tool 'npm.cmd' @('install', '--global', 'pyright')
# npm may use a custom global prefix instead of APPDATA/npm.
$npmPrefix = & npm.cmd prefix --global
if ($LASTEXITCODE -ne 0) { throw "npm prefix failed with exit code $LASTEXITCODE" }
if ($npmPrefix) { $env:PATH = ([string]($npmPrefix | Select-Object -Last 1)) + ';' + $env:PATH }
if ($PSCmdlet.ShouldProcess('Windows prerequisites', 'Verify installed commands and minimum versions')) {
    & (Join-Path $PSScriptRoot 'check-tools-windows.ps1')
}
Write-Host 'Tool setup completed. New terminals inherit PATH changes made by the package installers.'
Write-Host 'Use install-windows.ps1 to install the editor configuration, plugins, and parsers.'
