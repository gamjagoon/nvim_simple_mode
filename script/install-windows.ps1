<#
.SYNOPSIS
Optionally installs tools with WinGet, checks prerequisites, copies the Neovim configuration, installs plugins, and runs checks.
.DESCRIPTION
Native Windows x64. Existing configuration is moved to a timestamped backup.
The copied configuration does not require symlink privileges or this checkout to
remain in place. Rerun this installer after updating the repository.
.EXAMPLE
powershell -ExecutionPolicy Bypass -File script/install-windows.ps1
.EXAMPLE
powershell -ExecutionPolicy Bypass -File script/install-windows.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param([switch]$Help, [switch]$InstallTools)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
if ($Help) { Get-Help $PSCommandPath -Detailed; return }
if (-not $WhatIfPreference -and $env:OS -ne 'Windows_NT') { throw 'Run this installer in native Windows PowerShell. For WSL use install-linux.sh.' }
if ($env:NVIM_APPNAME -and $env:NVIM_APPNAME -ne 'nvim') { throw 'Unset NVIM_APPNAME before installing this configuration.' }

$project = Split-Path -Parent $PSScriptRoot
$sourceConfig = Join-Path $project 'nvim'
if (-not (Test-Path -LiteralPath (Join-Path $sourceConfig 'init.lua'))) { throw "Missing configuration: $sourceConfig" }
$localData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { '[LOCALAPPDATA]' }
$configBase = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $localData }
$config = Join-Path $configBase 'nvim'
$data = if ($env:XDG_DATA_HOME) { Join-Path $env:XDG_DATA_HOME 'nvim-data' } else { Join-Path $localData 'nvim-data' }

function Invoke-Nvim([string[]]$Arguments) {
    & nvim.exe @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Neovim failed with exit code $LASTEXITCODE" }
}
function Backup-Path([string]$Path) {
    if (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue) {
        $backup = $Path + '.backup.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
        Move-Item -LiteralPath $Path -Destination $backup
        Write-Host "Backed up $Path to $backup"
    }
}

if ($InstallTools) {
    & (Join-Path $PSScriptRoot 'install-tools-windows.ps1') -WhatIf:$WhatIfPreference
}
if ($PSCmdlet.ShouldProcess('LLVM-MinGW UCRT', 'Initialize compiler environment')) {
    . (Join-Path $PSScriptRoot 'windows-compiler.ps1')
    Initialize-WindowsCompiler
}
& (Join-Path $PSScriptRoot 'check-tools-windows.ps1') -WhatIf:$WhatIfPreference
if ($PSCmdlet.ShouldProcess($config, 'Back up existing config and copy repository configuration')) {
    $sourceFull = [IO.Path]::GetFullPath($sourceConfig).Replace('/', '\').TrimEnd('\')
    $configFull = [IO.Path]::GetFullPath($config).Replace('/', '\').TrimEnd('\')
    if ($sourceFull -eq $configFull -or $sourceFull.StartsWith($configFull + '\', [StringComparison]::OrdinalIgnoreCase) -or
        $configFull.StartsWith($sourceFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The repository nvim directory is the installation target; move the repository before installing.'
    }
    if (Test-Path -LiteralPath (Join-Path $data 'site\pack\packer')) {
        $dataFull = [IO.Path]::GetFullPath($data).Replace('/', '\').TrimEnd('\')
        if ($sourceFull.StartsWith($dataFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw 'The repository is inside legacy data that must be backed up; move the checkout before installing.'
        }
        Backup-Path $data
    }
    $savedLock = $null
    $installedLock = Join-Path $config 'lazy-lock.json'
    if (Test-Path -LiteralPath $installedLock -PathType Leaf) {
        $savedLock = [IO.File]::ReadAllText($installedLock)
    }
    Backup-Path $config
    New-Item -ItemType Directory -Force -Path $configBase | Out-Null
    Copy-Item -LiteralPath $sourceConfig -Destination $config -Recurse
    if ($null -ne $savedLock -and -not (Test-Path -LiteralPath (Join-Path $config 'lazy-lock.json'))) {
        [IO.File]::WriteAllText((Join-Path $config 'lazy-lock.json'), $savedLock, (New-Object System.Text.UTF8Encoding($false)))
    }
    Write-Host "Copied configuration to $config"
}
if ($PSCmdlet.ShouldProcess('Neovim plugins and Markdown parsers', 'Install or restore and verify')) {
    # Run from the checkout so Lua test paths remain portable even with spaces.
    Push-Location -LiteralPath $project
    try {
        # Bootstrap Lazy without loading UI modules that need uninstalled plugins.
        $bootstrap = "lua vim.go.loadplugins = true; vim.opt.rtp:prepend(vim.fn.stdpath('config')); require('plugins')"
        $pluginAction = if (Test-Path -LiteralPath (Join-Path $config 'lazy-lock.json') -PathType Leaf) { 'restore' } else { 'sync' }
        Invoke-Nvim @('--headless', '-u', 'NONE', ('+' + $bootstrap), ('+Lazy! ' + $pluginAction), "+lua if vim.v.errmsg ~= '' then vim.cmd('cquit 1') end", '+qa!')
        Invoke-Nvim @('--headless', "+lua require('nvim-treesitter').install({'markdown', 'markdown_inline'}):wait(300000)", '+qa!')
        Invoke-Nvim @('--headless', '+luafile tests/test_config.lua', '+qa!')
        Invoke-Nvim @('--headless', '+luafile tests/test_search.lua', '+qa!')
        Invoke-Nvim @('--headless', '+luafile tests/test_compat.lua', '+qa!')
    } finally { Pop-Location }
    Write-Host 'Installation and startup checks completed. Run nvim to start.'
}
