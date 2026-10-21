# Run in a fresh PowerShell session. External tools are mocked; no installation occurs.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$project = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([IO.Path]::GetTempPath()) ('nvim install test ' + [guid]::NewGuid().ToString('N'))
$savedEnv = @{}
foreach ($name in @('OS', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'NVIM_APPNAME', 'PATH', 'RUSTUP_AUTO_INSTALL')) {
    $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$global:NvimInstallTestCalls = New-Object 'System.Collections.Generic.List[string]'
$global:NvimInstallTestFailure = ''
$global:NvimToolTestCalls = 0
$global:NvimRustTestFailure = $false
$global:NvimVersionTestOld = ''
function global:nvim.exe {
    $global:NvimToolTestCalls++
    if ($args -contains '--version') { if ($global:NvimVersionTestOld -eq 'nvim') { 'NVIM v0.11.0' } else { 'NVIM v0.12.0' } }
    [void]$global:NvimInstallTestCalls.Add(($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($global:NvimInstallTestFailure -and ($args -join ' ').Contains($global:NvimInstallTestFailure)) {
        $global:LASTEXITCODE = 17
    }
}
function global:tree-sitter.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0; if ($global:NvimVersionTestOld -eq 'tree-sitter') { 'tree-sitter 0.26.0' } else { 'tree-sitter 0.26.1' } }
function global:fzf.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0; if ($global:NvimVersionTestOld -eq 'fzf') { '0.35.0' } else { '0.44.1' } }
function global:rust-analyzer.exe {
    if ($env:RUSTUP_AUTO_INSTALL -ne '0') { throw 'Rust toolchain auto-install was not disabled' }
    $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0
    if ($global:NvimRustTestFailure) { $global:LASTEXITCODE = 1 }
}
function global:rustfmt.exe {
    if ($env:RUSTUP_AUTO_INSTALL -ne '0') { throw 'Rust toolchain auto-install was not disabled' }
    $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0
}
function global:pyright-langserver.cmd { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:git.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:curl.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:fd.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:rg.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:clang.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0 }
function global:node.exe { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0; 'v24.0.0' }
function global:npm.cmd { $global:NvimToolTestCalls++; $global:LASTEXITCODE = 0; '11.0.0' }
try {
    $env:OS = 'Windows_NT'
    $env:LOCALAPPDATA = Join-Path $root 'local data'
    $env:XDG_CONFIG_HOME = Join-Path $root 'config root'
    $env:XDG_DATA_HOME = Join-Path $root 'data root'
    $env:NVIM_APPNAME = $null
    $env:RUSTUP_AUTO_INSTALL = '1'
    $installer = Join-Path $project 'script/install-windows.ps1'
    & $installer -WhatIf
    if (Test-Path -LiteralPath $root) { throw 'WhatIf changed the filesystem' }
    if ($global:NvimToolTestCalls -ne 0) { throw 'WhatIf executed a tool' }
    if ($env:PATH -ne $savedEnv['PATH']) { throw 'WhatIf changed PATH' }
    $global:NvimRustTestFailure = $true
    $rejected = $false
    try { & $installer } catch {
        $rejected = $_.ToString().Contains('https://rustup.rs/') -and $_.ToString().Contains('docs/windows-setup.md')
    }
    if (-not $rejected -or (Test-Path -LiteralPath $root)) { throw 'Unusable Rust tool did not fail before filesystem changes with manual guidance' }
    if ($env:RUSTUP_AUTO_INSTALL -ne '1') { throw 'Rustup environment was not restored after failed checks' }
    $global:NvimRustTestFailure = $false
    foreach ($oldTool in @('nvim', 'tree-sitter', 'fzf')) {
        $global:NvimVersionTestOld = $oldTool
        $rejected = $false
        try { & $installer } catch { $rejected = $_.ToString().Contains('requires >=') }
        if (-not $rejected -or (Test-Path -LiteralPath $root)) { throw "Outdated $oldTool was not rejected before filesystem changes" }
    }
    $global:NvimVersionTestOld = ''
    $global:NvimInstallTestCalls.Clear()
    $config = Join-Path $env:XDG_CONFIG_HOME 'nvim'
    $data = Join-Path $env:XDG_DATA_HOME 'nvim-data'
    New-Item -ItemType Directory -Force -Path $config, (Join-Path $data 'site/pack/packer') | Out-Null
    Set-Content -LiteralPath (Join-Path $config 'sentinel') -Value 'old config'
    Set-Content -LiteralPath (Join-Path $data 'sentinel') -Value 'old data'
    & $installer
    if ($env:RUSTUP_AUTO_INSTALL -ne '1') { throw 'Rustup environment was not restored after successful checks' }
    if (-not (Test-Path -LiteralPath (Join-Path $config 'init.lua'))) { throw 'Configuration was not copied' }
    $configBackups = @(Get-ChildItem -LiteralPath $env:XDG_CONFIG_HOME -Filter 'nvim.backup.*')
    $dataBackups = @(Get-ChildItem -LiteralPath $env:XDG_DATA_HOME -Filter 'nvim-data.backup.*')
    if ($configBackups.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $configBackups[0].FullName 'sentinel'))) {
        throw 'Configuration backup lost its sentinel'
    }
    if ($dataBackups.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $dataBackups[0].FullName 'sentinel'))) {
        throw 'Packer data backup lost its sentinel'
    }
    if ($global:NvimInstallTestCalls.Count -ne 5) { throw 'Missing preflight/restore/parser/startup/search invocations' }
    $global:NvimInstallTestCalls.Clear()
    $global:NvimInstallTestFailure = 'test_config.lua'
    $rejected = $false
    try { & $installer } catch { $rejected = $true }
    if (-not $rejected) { throw 'Startup failure was ignored' }
    if ($global:NvimInstallTestCalls -match 'test_search.lua') { throw 'Continued after failed startup' }

    # Backing up legacy data must not move the checkout containing the installer.
    $global:NvimInstallTestFailure = ''
    $env:XDG_DATA_HOME = Join-Path $root 'nested data'
    $env:XDG_CONFIG_HOME = Join-Path $root 'nested config'
    $nestedData = Join-Path $env:XDG_DATA_HOME 'nvim-data'
    $nestedProject = Join-Path $nestedData 'checkout'
    New-Item -ItemType Directory -Force -Path (Join-Path $nestedData 'site/pack/packer'),
        (Join-Path $nestedProject 'script'), (Join-Path $nestedProject 'nvim') | Out-Null
    Copy-Item -LiteralPath $installer -Destination (Join-Path $nestedProject 'script/install-windows.ps1')
    Copy-Item -LiteralPath (Join-Path $project 'script/check-tools-windows.ps1') -Destination (Join-Path $nestedProject 'script/check-tools-windows.ps1')
    Set-Content -LiteralPath (Join-Path $nestedProject 'nvim/init.lua') -Value '-- fixture'
    $rejected = $false
    try { & (Join-Path $nestedProject 'script/install-windows.ps1') } catch { $rejected = $true }
    if (-not $rejected -or -not (Test-Path -LiteralPath (Join-Path $nestedProject 'nvim/init.lua')) -or
        (Test-Path -LiteralPath $env:XDG_CONFIG_HOME)) { throw 'Nested checkout was not safely rejected' }
    if ($env:PATH -ne $savedEnv['PATH']) { throw 'Installer changed PATH' }
    Write-Output 'PASS: Windows installer WhatIf, spaced paths, copied config/backups and failure propagation (mock tools)'
} finally {
    foreach ($name in $savedEnv.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnv[$name], 'Process') }
    foreach ($name in @('nvim.exe', 'tree-sitter.exe', 'fzf.exe', 'rust-analyzer.exe', 'rustfmt.exe', 'pyright-langserver.cmd',
        'git.exe', 'curl.exe', 'fd.exe', 'rg.exe', 'clang.exe', 'node.exe', 'npm.cmd')) {
        Remove-Item -LiteralPath ('Function:\' + $name) -ErrorAction SilentlyContinue
    }
    Remove-Variable NvimInstallTestCalls, NvimInstallTestFailure, NvimToolTestCalls, NvimRustTestFailure, NvimVersionTestOld -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
