# Run in a fresh PowerShell process. All installers and the final checker are mocked.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$project = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([IO.Path]::GetTempPath()) ('earlgrey winget test ' + [guid]::NewGuid().ToString('N'))
$savedEnv = @{}
foreach ($name in @('OS', 'PATH', 'USERPROFILE', 'LOCALAPPDATA', 'APPDATA', 'PROCESSOR_ARCHITECTURE', 'PROCESSOR_ARCHITEW6432', 'ProgramFiles(x86)')) {
    $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$global:WingetTestCalls = New-Object 'System.Collections.Generic.List[string]'
$global:WingetTestFailure = ''
$global:WingetTestExit = 17
$global:WingetTestNoActive = $false
$global:WingetTestCppMissing = $false
$vswherePath = $null
function global:winget.exe {
    [void]$global:WingetTestCalls.Add('winget ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($global:WingetTestFailure -eq 'winget') { $global:LASTEXITCODE = $global:WingetTestExit }
}
function global:rustup.exe {
    [void]$global:WingetTestCalls.Add('rustup ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($args -contains 'show' -or $args -contains 'default') { 'stable-x86_64-pc-windows-msvc (default)' }
    if ($global:WingetTestNoActive -and $args -contains 'show') { $global:LASTEXITCODE = 1 }
    if ($global:WingetTestFailure -eq 'rustup' -and $args -contains 'update') { $global:LASTEXITCODE = 17 }
}
function global:npm.cmd {
    [void]$global:WingetTestCalls.Add('npm ' + ($args -join ' '))
    $global:LASTEXITCODE = 0
    if ($args -contains 'prefix') { Join-Path $env:APPDATA 'custom npm' }
    if ($global:WingetTestFailure -eq 'npm') { $global:LASTEXITCODE = 17 }
}
function global:Start-Process {
    param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru)
    [void]$global:WingetTestCalls.Add('setup ' + ($ArgumentList -join ' '))
    if (-not $Wait -or -not $PassThru) { throw 'Workload installation must wait and inspect status' }
    $global:WingetTestCppMissing = $false
    if ($global:WingetTestFailure -eq 'setup') { return [pscustomobject]@{ ExitCode = 17 } }
    return [pscustomobject]@{ ExitCode = 0 }
}
try {
    New-Item -ItemType Directory -Path $root | Out-Null
    $installer = Join-Path $root 'install-tools-windows.ps1'
    Copy-Item -LiteralPath (Join-Path $project 'script/install-tools-windows.ps1') -Destination $installer
    Set-Content -LiteralPath (Join-Path $root 'check-tools-windows.ps1') -Value '[void]$global:WingetTestCalls.Add("checker")'
    $env:OS = 'Windows_NT'
    $env:PROCESSOR_ARCHITECTURE = 'AMD64'
    $env:PROCESSOR_ARCHITEW6432 = $null
    $env:USERPROFILE = Join-Path $root 'user'
    $env:LOCALAPPDATA = Join-Path $root 'local'
    $env:APPDATA = Join-Path $root 'roaming'
    ${env:ProgramFiles(x86)} = Join-Path $root 'program files x86'
    $vsInstaller = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer'
    New-Item -ItemType Directory -Path $vsInstaller -Force | Out-Null
    $vswherePath = Join-Path $vsInstaller 'vswhere.exe'
    Set-Content -LiteralPath $vswherePath -Value 'mocked; never execute'
    Set-Item -Path ('Function:global:' + $vswherePath) -Value {
        [void]$global:WingetTestCalls.Add('vswhere ' + ($args -join ' '))
        $global:LASTEXITCODE = 0
        if (-not ($args -contains '-requires') -or -not $global:WingetTestCppMissing) { 'C:\Build Tools' }
    }
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
    if (-not ($packages -match 'Microsoft.VisualStudio.*BuildTools')) { throw 'Default installation omitted C++ build tools' }
    if (-not ($global:WingetTestCalls -match '^rustup update stable$')) { throw 'Stable Rust was not updated' }
    if (-not ($global:WingetTestCalls -match '^rustup component add rust-analyzer rustfmt$')) { throw 'Active Rust toolchain components were not installed' }
    if ($global:WingetTestCalls -match '^rustup default stable$') { throw 'Existing Rust default was changed' }
    if (-not ($global:WingetTestCalls -match '^npm install (--global|-g) pyright$')) { throw 'Pyright installation missing' }
    if ($global:WingetTestCalls[$global:WingetTestCalls.Count - 1] -ne 'checker') { throw 'Final tool check did not run last' }
    if (-not $env:PATH.StartsWith((Join-Path $env:APPDATA 'custom npm') + ';')) { throw 'Custom npm prefix was not added to process PATH' }

    if ($global:WingetTestCalls -match '^setup ') { throw 'Already-installed C++ workload was modified' }
    $global:WingetTestCalls.Clear()
    $global:WingetTestCppMissing = $true
    & $installer
    if (-not ($global:WingetTestCalls -match '^setup modify .*--add Microsoft.VisualStudio.Workload.VCTools')) { throw 'Missing C++ workload was not installed' }
    $global:WingetTestCalls.Clear()
    $global:WingetTestCppMissing = $true
    $global:WingetTestFailure = 'setup'
    $rejected = $false
    try { & $installer } catch { $rejected = $true }
    if (-not $rejected -or $global:WingetTestCalls -match '^(rustup|npm|checker)') { throw 'Workload installation failure did not halt dependent work' }
    $global:WingetTestFailure = ''
    $global:WingetTestCppMissing = $false
    $global:WingetTestCalls.Clear()
    & $installer -SkipBuildTools
    if ($global:WingetTestCalls -match 'Microsoft.VisualStudio.*BuildTools|^vswhere |^setup ') { throw 'SkipBuildTools was ignored' }
    $global:WingetTestCalls.Clear()
    $global:WingetTestNoActive = $true
    & $installer -SkipBuildTools
    if (-not ($global:WingetTestCalls -contains 'rustup default stable')) { throw 'Fresh Rust installation did not establish a default' }
    $global:WingetTestNoActive = $false
    foreach ($tool in @('winget', 'rustup', 'npm')) {
        $global:WingetTestCalls.Clear()
        $global:WingetTestFailure = $tool
        $rejected = $false
        try { & $installer -SkipBuildTools } catch { $rejected = $true }
        if (-not $rejected) { throw "$tool failure was ignored" }
        if ($global:WingetTestCalls -contains 'checker') { throw "Checker ran after $tool failure" }
        if ($tool -eq 'winget' -and $global:WingetTestCalls -match '^(rustup|npm) ') { throw 'Continued toolchain installation after winget failure' }
        if ($tool -eq 'rustup' -and $global:WingetTestCalls -match '^npm ') { throw 'Continued npm installation after Rust failure' }
    }
    $global:WingetTestCalls.Clear()
    $global:WingetTestFailure = 'winget'
    $global:WingetTestExit = -1978335189 # 0x8A15002B: no applicable upgrade
    & $installer -SkipBuildTools
    if ($global:WingetTestCalls[$global:WingetTestCalls.Count - 1] -ne 'checker') { throw 'Already-current packages prevented final checks' }
    Write-Output 'PASS: winget arguments, WhatIf, Rust/Pyright setup, C++ workload verification/repair, SkipBuildTools, no-upgrade code, and failure propagation (mocked)'
} finally {
    foreach ($name in $savedEnv.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnv[$name], 'Process') }
    foreach ($name in @('winget.exe', 'rustup.exe', 'npm.cmd', 'Start-Process')) { Remove-Item -LiteralPath ('Function:\' + $name) -ErrorAction SilentlyContinue }
    if ($vswherePath) { Remove-Item -LiteralPath ('Function:' + $vswherePath) -ErrorAction SilentlyContinue }
    Remove-Variable WingetTestCalls, WingetTestFailure, WingetTestExit, WingetTestNoActive, WingetTestCppMissing -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
