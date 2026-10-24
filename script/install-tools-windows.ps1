<#
.SYNOPSIS
Installs Windows x64 tools using WinGet, LLVM-MinGW UCRT, and Rust gnullvm.
.DESCRIPTION
No Visual Studio Build Tools or Microsoft SDK installation is requested.
Uses the winget community source and accepts package/source agreements.
Changes only the current process PATH directly; package installers can register PATH.
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File script/install-tools-windows.ps1
.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File script/install-tools-windows.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$Help)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ($Help) { Get-Help $PSCommandPath -Detailed; return }
if (-not $WhatIfPreference -and $env:OS -ne 'Windows_NT') {
    throw 'Run this installer in native Windows PowerShell. For WSL use install-tools-linux.sh.'
}
$toolchain = 'stable-x86_64-pc-windows-gnullvm'
$packages = @(
    'Neovim.Neovim', 'Git.Git', 'cURL.cURL', 'sharkdp.fd',
    'BurntSushi.ripgrep.MSVC', 'junegunn.fzf', 'tree-sitter.tree-sitter-cli',
    'OpenJS.NodeJS.LTS', 'MartinStorsjo.LLVM-MinGW.UCRT', 'Rustlang.Rustup'
)
if ($WhatIfPreference) {
    foreach ($id in $packages) {
        [void]$PSCmdlet.ShouldProcess($id, 'winget install --exact --source winget (accepts agreements)')
    }
    [void]$PSCmdlet.ShouldProcess('Current process', 'Refresh PATH and initialize LLVM-MinGW UCRT')
    [void]$PSCmdlet.ShouldProcess($toolchain, 'Install using rustup with rustfmt, rust-analyzer, rust-mingw; preserve existing default')
    [void]$PSCmdlet.ShouldProcess('Pyright and prerequisites', 'Install via npm and run tool checks')
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
    $parts = @(
        [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'Machine') + ''),
        [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'User') + ''),
        $env:PATH
    )
    if ($env:LLVM_MINGW_ROOT) { $parts = @((Join-Path $env:LLVM_MINGW_ROOT 'bin')) + $parts }
    $cargoHome = $env:CARGO_HOME
    if (-not $cargoHome) { $cargoHome = [Environment]::GetEnvironmentVariable('CARGO_HOME', 'User') }
    if (-not $cargoHome) { $cargoHome = [Environment]::GetEnvironmentVariable('CARGO_HOME', 'Machine') }
    if ($cargoHome) { $parts += (Join-Path $cargoHome 'bin') }
    elseif ($env:USERPROFILE) { $parts += (Join-Path $env:USERPROFILE '.cargo\bin') }
    if ($env:APPDATA) { $parts += (Join-Path $env:APPDATA 'npm') }
    if ($env:LOCALAPPDATA) { $parts += (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links') }
    if ($env:ProgramFiles) { $parts += (Join-Path $env:ProgramFiles 'WinGet\Links') }
    $seen = @{}
    $paths = @()
    foreach ($part in $parts) {
        foreach ($entry in ($part -split ';')) {
            if ($entry -and -not $seen.ContainsKey($entry)) { $seen[$entry] = $true; $paths += $entry }
        }
    }
    $env:PATH = $paths -join ';'
}
# Refresh stale shells before deciding whether Rustup is genuinely absent.
if (-not $PSCmdlet.ShouldProcess('Current process', 'Refresh PATH before detecting existing Rustup')) { return }
Update-ToolPath
foreach ($id in $packages) {
    if ($id -eq 'Rustlang.Rustup' -and (Get-Command rustup.exe -ErrorAction SilentlyContinue)) {
        # Re-running rustup-init with --default-* would overwrite an existing default.
        Invoke-Tool 'rustup.exe' @('--version')
        Write-Host 'Using existing Rustup; its global default host/toolchain will be retained.'
        continue
    }
    if ($id -eq 'Rustlang.Rustup') {
        $rustupHome = $env:RUSTUP_HOME
        if (-not $rustupHome) { $rustupHome = [Environment]::GetEnvironmentVariable('RUSTUP_HOME', 'User') }
        if (-not $rustupHome) { $rustupHome = [Environment]::GetEnvironmentVariable('RUSTUP_HOME', 'Machine') }
        if (-not $rustupHome -and $env:USERPROFILE) { $rustupHome = Join-Path $env:USERPROFILE '.rustup' }
        if ($rustupHome -and (Test-Path -LiteralPath (Join-Path $rustupHome 'settings.toml') -PathType Leaf)) {
            throw 'Existing Rustup settings were found but rustup.exe is unavailable after PATH refresh. Restore its Cargo bin/PATH before rerunning; existing defaults will not be overwritten.'
        }
    }
    if (-not $PSCmdlet.ShouldProcess($id, 'Install or upgrade with winget')) { return }
    $arguments = @('install', '--id', $id, '--exact', '--source', 'winget', '--architecture', 'x64',
        '--silent', '--disable-interactivity', '--accept-package-agreements', '--accept-source-agreements')
    if ($id -eq 'Rustlang.Rustup') {
        # Avoid rustup-init's default MSVC host and Visual Studio bootstrap prompt.
        $arguments += @('--override', '-y --default-host x86_64-pc-windows-gnullvm --default-toolchain stable --profile minimal')
    }
    & winget.exe @arguments
    $code = $LASTEXITCODE
    $unsignedCode = [long]$code -band 4294967295L
    if ($code -eq -1978334967 -or $code -eq -1978334966) {
        throw "winget requires a Windows restart for $id (exit $code). Restart Windows and rerun."
    }
    if ($code -ne 0 -and $unsignedCode -ne 2316632107L -and $unsignedCode -ne 2316632161L) {
        throw "winget failed for $id with exit code $code"
    }
}
if (-not $PSCmdlet.ShouldProcess('Current process', 'Refresh PATH and select LLVM-MinGW')) { return }
Update-ToolPath
. (Join-Path $PSScriptRoot 'windows-compiler.ps1')
Initialize-WindowsCompiler
if (-not $PSCmdlet.ShouldProcess($toolchain, 'Install Rust tools without changing an existing default')) { return }
Invoke-Tool 'rustup.exe' @('toolchain', 'install', $toolchain, '--profile', 'minimal',
    '--component', 'rust-analyzer', '--component', 'rustfmt', '--component', 'rust-mingw')
if (-not $PSCmdlet.ShouldProcess('Pyright', 'Install with npm')) { return }
Invoke-Tool 'npm.cmd' @('install', '--global', 'pyright')
$npmPrefix = & npm.cmd prefix --global
if ($LASTEXITCODE -ne 0) { throw "npm prefix failed with exit code $LASTEXITCODE" }
if ($npmPrefix) { $env:PATH = ([string]($npmPrefix | Select-Object -Last 1)) + ';' + $env:PATH }
if ($PSCmdlet.ShouldProcess('Windows prerequisites', 'Verify installed tools and GNU LLVM host')) {
    & (Join-Path $PSScriptRoot 'check-tools-windows.ps1')
}
Write-Host 'Tool setup completed: LLVM-MinGW UCRT and Rust gnullvm; existing Rust defaults are retained.'
Write-Host 'Use install-windows.ps1 to install the editor configuration and plugins.'
