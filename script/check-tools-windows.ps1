<#
.SYNOPSIS
Checks manually installed Windows tools and prints official download links.
.DESCRIPTION
Read-only prerequisite check for native Windows x64. Install the latest stable
releases using the linked official pages, then open a new terminal and rerun.
This script never downloads tools or changes PATH. See docs/windows-setup.md.
.EXAMPLE
powershell -ExecutionPolicy Bypass -File script/check-tools-windows.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$Help)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ($Help) { Get-Help $PSCommandPath -Detailed; return }

$tools = @(
    @{ Command = 'nvim.exe'; Minimum = '0.12.0'; Url = 'https://github.com/neovim/neovim/releases/latest' }
    @{ Command = 'git.exe'; Minimum = ''; Url = 'https://git-scm.com/downloads/win' }
    @{ Command = 'curl.exe'; Minimum = ''; Url = 'https://curl.se/windows/' }
    @{ Command = 'fd.exe'; Minimum = ''; Url = 'https://github.com/sharkdp/fd/releases/latest' }
    @{ Command = 'rg.exe'; Minimum = ''; Url = 'https://github.com/BurntSushi/ripgrep/releases/latest' }
    @{ Command = 'fzf.exe'; Minimum = '0.52.1'; Url = 'https://github.com/junegunn/fzf/releases/latest' }
    @{ Command = 'tree-sitter.exe'; Minimum = '0.26.1'; Url = 'https://github.com/tree-sitter/tree-sitter/releases/latest' }
    @{ Command = 'node.exe'; Minimum = ''; Url = 'https://nodejs.org/en/download' }
    @{ Command = 'npm.cmd'; Minimum = ''; Url = 'https://nodejs.org/en/download' }
    @{ Command = 'cargo.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'rustc.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'rustup.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'rust-analyzer.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'rustfmt.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'pyright-langserver.cmd'; Minimum = ''; Url = 'https://github.com/microsoft/pyright/blob/main/docs/installation.md' }
)
Write-Host 'Install Windows x64 tools using install-tools-windows.ps1 or these official pages:'
foreach ($tool in $tools) { Write-Host ('  {0}: {1}' -f $tool.Command, $tool.Url) }
Write-Host '  LLVM-MinGW UCRT x64: https://github.com/mstorsjo/llvm-mingw/releases'
Write-Host '  Rust host: stable-x86_64-pc-windows-gnullvm'
Write-Host 'Setup instructions: docs/windows-setup.md'
if ($WhatIfPreference) { return }
if ($env:OS -ne 'Windows_NT') { throw 'Run this checker in native Windows PowerShell. For WSL use install-linux.sh.' }
$failures = @()
. (Join-Path $PSScriptRoot 'windows-compiler.ps1')
try { $null = Get-WindowsCompiler } catch { $failures += [string]$_ }
$originalRustAutoInstall = [Environment]::GetEnvironmentVariable('RUSTUP_AUTO_INSTALL', 'Process')
try {
    [Environment]::SetEnvironmentVariable('RUSTUP_AUTO_INSTALL', '0', 'Process')
    foreach ($tool in $tools) {
        $command = $tool.Command
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            $failures += "$command is missing. Install: $($tool.Url)"
            continue
        }
        if ($command -eq 'pyright-langserver.cmd') { continue }
        try {
            $output = (& $command --version 2>&1) -join ' '
            if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE; $output" }
            if ($tool.Minimum -and ($output -notmatch '(\d+\.\d+\.\d+)' -or [version]$Matches[1] -lt [version]$tool.Minimum)) {
                throw "requires >= $($tool.Minimum); found: $output"
            }
        } catch { $failures += "$command is not usable: $_. Install/update: $($tool.Url)" }
    }
    try {
        $hostInfo = (& rustc.exe -vV 2>&1) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $hostInfo -notmatch '(?m)^host: x86_64-pc-windows-gnullvm\s*$') { throw 'Rust host must be x86_64-pc-windows-gnullvm.' }
        $active = (& rustup.exe show active-toolchain 2>&1) -join ' '
        if ($LASTEXITCODE -ne 0 -or $active -notmatch '^stable-x86_64-pc-windows-gnullvm(?:\s|$)') { throw 'Select stable-x86_64-pc-windows-gnullvm for this process.' }
    } catch { $failures += [string]$_ }
} finally {
    [Environment]::SetEnvironmentVariable('RUSTUP_AUTO_INSTALL', $originalRustAutoInstall, 'Process')
}
if ($failures.Count -gt 0) { throw (($failures -join [Environment]::NewLine) + [Environment]::NewLine + 'Follow docs/windows-setup.md, then rerun this checker.') }
Write-Host 'Required commands passed. Parser installation verifies compilation with LLVM-MinGW.'
