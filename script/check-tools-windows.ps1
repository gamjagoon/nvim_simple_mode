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
    @{ Command = 'fzf.exe'; Minimum = '0.36.0'; Url = 'https://github.com/junegunn/fzf/releases/latest' }
    @{ Command = 'tree-sitter.exe'; Minimum = '0.26.1'; Url = 'https://github.com/tree-sitter/tree-sitter/releases/latest' }
    @{ Command = 'clang.exe'; Minimum = ''; Url = 'https://github.com/llvm/llvm-project/releases/latest' }
    @{ Command = 'node.exe'; Minimum = ''; Url = 'https://nodejs.org/en/download' }
    @{ Command = 'npm.cmd'; Minimum = ''; Url = 'https://nodejs.org/en/download' }
    @{ Command = 'rust-analyzer.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'rustfmt.exe'; Minimum = ''; Url = 'https://rustup.rs/' }
    @{ Command = 'pyright-langserver.cmd'; Minimum = ''; Url = 'https://github.com/microsoft/pyright/blob/main/docs/installation.md' }
)
Write-Host 'Install Windows x64 tools manually from these official pages (latest stable releases; Node.js LTS):'
foreach ($tool in $tools) { Write-Host ('  {0}: {1}' -f $tool.Command, $tool.Url) }
Write-Host '  MSVC Build Tools and Windows SDK (Desktop development with C++): https://visualstudio.microsoft.com/downloads/'
Write-Host 'Setup instructions: docs/windows-setup.md'
if ($WhatIfPreference) { return }
if ($env:OS -ne 'Windows_NT') { throw 'Run this checker in native Windows PowerShell. For WSL use install-linux.sh.' }

$failures = @()
$originalRustAutoInstall = [Environment]::GetEnvironmentVariable('RUSTUP_AUTO_INSTALL', 'Process')
try {
    # Rustup proxies can install a missing selected toolchain even for --version.
    [Environment]::SetEnvironmentVariable('RUSTUP_AUTO_INSTALL', '0', 'Process')
    foreach ($tool in $tools) {
        $command = $tool.Command
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            $failures += "$command is missing. Install manually: $($tool.Url)"
            continue
        }
        # The language server uses stdio, not --version. Its Node runtime is checked separately.
        if ($command -eq 'pyright-langserver.cmd') { continue }
        try {
            $output = (& $command --version 2>&1) -join ' '
            if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE; $output" }
            if ($tool.Minimum -and ($output -notmatch '(\d+\.\d+\.\d+)' -or
                [version]$Matches[1] -lt [version]$tool.Minimum)) {
                throw "requires >= $($tool.Minimum); found: $output"
            }
        } catch {
            $failures += "$command is not usable: $_. Install/update manually: $($tool.Url)"
        }
    }
} finally {
    [Environment]::SetEnvironmentVariable('RUSTUP_AUTO_INSTALL', $originalRustAutoInstall, 'Process')
}
if ($failures.Count -gt 0) {
    throw (($failures -join [Environment]::NewLine) + [Environment]::NewLine +
        'Follow docs/windows-setup.md, open a new terminal, then rerun this checker.')
}
Write-Host 'Required commands passed. Parser installation will verify the compiler/SDK environment.'
