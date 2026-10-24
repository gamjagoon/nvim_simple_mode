# Run in a fresh PowerShell process. All installers and the final checker are mocked.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$project = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([IO.Path]::GetTempPath()) ('earlgrey winget test ' + [guid]::NewGuid().ToString('N'))
$savedEnv = @{}
foreach ($name in @('OS', 'PATH', 'USERPROFILE', 'LOCALAPPDATA', 'APPDATA', 'PROCESSOR_ARCHITECTURE', 'PROCESSOR_ARCHITEW6432', 'ProgramFiles(x86)', 'CC', 'CXX', 'RUSTUP_TOOLCHAIN', 'RUSTUP_HOME', 'CARGO_HOME')) {
    $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$global:WingetTestCalls = New-Object 'System.Collections.Generic.List[string]'
$global:WingetTestFailure = ''
$global:WingetTestExit = 17
$global:WingetTestRustupAvailable = $true
$global:WingetTestRustupHiddenBin = $null
function global:Get-Command {
    [CmdletBinding()]
    param([Parameter(Position=0)][string[]]$Name)
    if ($Name -contains 'rustup.exe' -and -not $global:WingetTestRustupAvailable) {
        if ($global:WingetTestRustupHiddenBin -and ($env:PATH -split ';') -contains $global:WingetTestRustupHiddenBin) {
            $global:WingetTestRustupAvailable = $true
        } else { return }
    }
    Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
}

function global:winget.exe {
    [void]$global:WingetTestCalls.Add('winget ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($global:WingetTestFailure -eq 'winget') { $global:LASTEXITCODE = $global:WingetTestExit }
    if ($LASTEXITCODE -eq 0 -and $args -contains 'Rustlang.Rustup') { $global:WingetTestRustupAvailable = $true }
}
function global:rustup.exe {
    [void]$global:WingetTestCalls.Add('rustup ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($args -contains 'show' -or $args -contains 'default') { 'stable-x86_64-pc-windows-msvc (default)' }
    if ($global:WingetTestFailure -eq 'rustup' -and $args -contains 'install') { $global:LASTEXITCODE = 17 }
}
function global:npm.cmd {
    [void]$global:WingetTestCalls.Add('npm ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($args -contains 'prefix') { Join-Path $env:APPDATA 'custom npm' }
    if ($global:WingetTestFailure -eq 'npm') { $global:LASTEXITCODE = 17 }
}
try {
    New-Item -ItemType Directory -Path $root | Out-Null
    $installer = Join-Path $root 'install-tools-windows.ps1'
    Copy-Item -LiteralPath (Join-Path $project 'script/install-tools-windows.ps1') -Destination $installer
    Set-Content -LiteralPath (Join-Path $root 'check-tools-windows.ps1') -Value '[void]$global:WingetTestCalls.Add("checker")'
    Set-Content -LiteralPath (Join-Path $root 'windows-compiler.ps1') -Value @'
function Initialize-WindowsCompiler {
    [void]$global:WingetTestCalls.Add('compiler')
    $env:RUSTUP_TOOLCHAIN = 'stable-x86_64-pc-windows-gnullvm'
}
'@
    $env:OS = 'Windows_NT'
    $env:PROCESSOR_ARCHITECTURE = 'AMD64'
    $env:PROCESSOR_ARCHITEW6432 = $null
    $env:USERPROFILE = Join-Path $root 'user'
    $env:LOCALAPPDATA = Join-Path $root 'local'
    $env:APPDATA = Join-Path $root 'roaming'
    $env:CARGO_HOME = $null
    $env:RUSTUP_HOME = Join-Path $root 'rustup state'
    $beforeFiles = @(Get-ChildItem -LiteralPath $root -Recurse).Count
    $beforePath = $env:PATH
    & $installer -WhatIf
    if ($global:WingetTestCalls.Count -ne 0) { throw 'WhatIf executed a package tool or checker' }
    if ($env:PATH -ne $beforePath) { throw 'WhatIf changed PATH' }
    if (@(Get-ChildItem -LiteralPath $root -Recurse).Count -ne $beforeFiles) { throw 'WhatIf changed files' }

    & $installer
    $packages = @($global:WingetTestCalls | Where-Object { $_ -like 'winget install *' })
    if ($packages.Count -lt 8) { throw 'Expected native tool packages were not installed' }
    foreach ($call in $packages) {
        foreach ($flag in @('--exact', '--source winget', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity', '--architecture x64')) {
            if (-not $call.Contains($flag)) { throw "Missing required winget flag $flag in $call" }
        }
    }
    if ($packages -match 'LLVM.LLVM|Microsoft.VisualStudio') { throw 'MSVC/standalone LLVM dependency remains' }
    if (-not ($packages -match 'MartinStorsjo.LLVM-MinGW.UCRT')) { throw 'LLVM-MinGW package missing' }
    if ($packages -match 'Rustlang.Rustup') { throw 'Existing rustup was bootstrapped again, risking global default changes' }
    if (-not ($global:WingetTestCalls -contains 'compiler')) { throw 'Compiler environment not initialized' }
    if (-not ($global:WingetTestCalls -match '^rustup toolchain install stable-x86_64-pc-windows-gnullvm .*--component rust-analyzer.*--component rustfmt.*--component rust-mingw')) { throw 'gnullvm Rust toolchain/components missing' }
    if ($global:WingetTestCalls -match '^rustup default') { throw 'Global Rust default was changed' }
    if (-not ($global:WingetTestCalls -match '^npm install (--global|-g) pyright$')) { throw 'Pyright installation missing' }
    if ($global:WingetTestCalls[$global:WingetTestCalls.Count - 1] -ne 'checker') { throw 'Final tool check did not run last' }
    if (-not $env:PATH.StartsWith((Join-Path $env:APPDATA 'custom npm') + ';')) { throw 'Custom npm prefix was not added to process PATH' }

    # Existing Rustup in a custom Cargo home must be found before bootstrap.
    $global:WingetTestCalls.Clear()
    $env:CARGO_HOME = Join-Path $root 'custom cargo home'
    $global:WingetTestRustupHiddenBin = Join-Path $env:CARGO_HOME 'bin'
    $global:WingetTestRustupAvailable = $false
    & $installer
    if ($global:WingetTestCalls -match '^winget .*Rustlang.Rustup') { throw 'Stale PATH caused existing Rustup bootstrap' }
    if (-not $global:WingetTestRustupAvailable) { throw 'Custom Cargo bin was not refreshed before Rustup discovery' }
    $global:WingetTestRustupHiddenBin = $null
    $env:CARGO_HOME = $null

    # Settings without a usable rustup binary must never be treated as fresh.
    $global:WingetTestCalls.Clear()
    $global:WingetTestRustupAvailable = $false
    New-Item -ItemType Directory -Force -Path $env:RUSTUP_HOME | Out-Null
    $settings = Join-Path $env:RUSTUP_HOME 'settings.toml'
    Set-Content -LiteralPath $settings -Value 'preserved default'
    $rejected = $false
    try { & $installer } catch { $rejected = [string]$_ -match 'Existing Rustup settings' }
    if (-not $rejected -or $global:WingetTestCalls -match '^winget .*Rustlang.Rustup|^rustup toolchain|^checker$') { throw 'Existing Rustup settings were not protected' }
    if ((Get-Content -LiteralPath $settings) -ne 'preserved default') { throw 'Existing Rustup settings changed' }
    Remove-Item -LiteralPath $settings

    $global:WingetTestCalls.Clear()
    $global:WingetTestRustupAvailable = $false
    & $installer
    if (-not ($global:WingetTestCalls -match '^winget install .*Rustlang.Rustup .*--override .*--default-host x86_64-pc-windows-gnullvm')) { throw 'Fresh rustup bootstrap did not select gnullvm host' }
    if (-not ($global:WingetTestCalls -match '^rustup toolchain install stable-x86_64-pc-windows-gnullvm')) { throw 'Fresh bootstrap did not install explicit toolchain' }
    if (-not $global:WingetTestRustupAvailable) { throw 'Fresh Rustup fixture never installed' }
    foreach ($tool in @('winget', 'rustup', 'npm')) {
        $global:WingetTestCalls.Clear()
        $global:WingetTestFailure = $tool
        $rejected = $false
        try { & $installer } catch { $rejected = $true }
        if (-not $rejected) { throw "$tool failure was ignored" }
        if ($global:WingetTestCalls -contains 'checker') { throw "Checker ran after $tool failure" }
        if ($tool -eq 'winget' -and $global:WingetTestCalls -match '^(rustup|npm) ') { throw 'Continued toolchain installation after winget failure' }
        if ($tool -eq 'rustup' -and $global:WingetTestCalls -match '^npm ') { throw 'Continued npm installation after Rust failure' }
    }
    $global:WingetTestCalls.Clear()
    $global:WingetTestFailure = 'winget'
    $global:WingetTestExit = -1978335189 # 0x8A15002B: no applicable upgrade
    & $installer
    if ($global:WingetTestCalls[$global:WingetTestCalls.Count - 1] -ne 'checker') { throw 'Already-current packages prevented final checks' }
    Write-Output 'PASS: winget arguments, WhatIf, Rust/Pyright setup, LLVM-MinGW/gnullvm selection, no-upgrade code, and failure propagation (mocked)'
} finally {
    foreach ($name in $savedEnv.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnv[$name], 'Process') }
    foreach ($name in @('winget.exe', 'rustup.exe', 'npm.cmd', 'Start-Process', 'Get-Command')) { Remove-Item -LiteralPath ('Function:\' + $name) -ErrorAction SilentlyContinue }
    Remove-Variable WingetTestCalls, WingetTestFailure, WingetTestExit, WingetTestRustupAvailable, WingetTestRustupHiddenBin -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
