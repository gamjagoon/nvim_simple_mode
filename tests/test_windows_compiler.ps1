# Real helper/checker with synthetic LLVM-MinGW drivers; no native compilation.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$project = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([IO.Path]::GetTempPath()) ('LLVM MinGW fixture ' + [guid]::NewGuid().ToString('N'))
$saved = @{}
$names = @('OS','CC','CXX','CFLAGS','CXXFLAGS','PATH','LLVM_MINGW_ROOT','RUSTUP_TOOLCHAIN','RUSTUP_AUTO_INSTALL','CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER')
foreach ($target in @('x86_64-pc-windows-msvc','x86_64_pc_windows_msvc','x86_64-pc-windows-gnullvm','x86_64_pc_windows_gnullvm')) { foreach ($prefix in @('CC_','CXX_','CFLAGS_','CXXFLAGS_')) { $names += $prefix + $target } }
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
$global:CompilerTestTarget = 'x86_64-w64-windows-gnu'
$global:CompilerTestRustHost = 'x86_64-pc-windows-gnullvm'
$driverPaths = @()
function global:nvim.exe { $global:LASTEXITCODE=0; 'NVIM v0.12.0' }
function global:tree-sitter.exe { $global:LASTEXITCODE=0; 'tree-sitter 0.26.1' }
function global:fzf.exe { $global:LASTEXITCODE=0; '0.52.1' }
function global:rustc.exe { $global:LASTEXITCODE=0; 'host: ' + $global:CompilerTestRustHost }
function global:rustup.exe { $global:LASTEXITCODE=0; 'stable-x86_64-pc-windows-gnullvm (environment override)' }
$toolNames = @('cargo.exe','git.exe','curl.exe','fd.exe','rg.exe','node.exe','npm.cmd','rust-analyzer.exe','rustfmt.exe','pyright-langserver.cmd')
foreach ($name in $toolNames) { Set-Item -Path ('Function:global:'+$name) -Value { $global:LASTEXITCODE=0 } }
try {
    $env:OS='Windows_NT'
    $env:LLVM_MINGW_ROOT=$root
    New-Item -ItemType Directory -Path (Join-Path $root 'bin') -Force | Out-Null
    $global:CompilerTestLibrary=Join-Path $root 'libucrt.a'
    Set-Content $global:CompilerTestLibrary 'mock library'
    foreach ($name in @('x86_64-w64-mingw32-clang.exe','x86_64-w64-mingw32-clang++.exe')) {
        $path=Join-Path (Join-Path $root 'bin') $name
        $driverPaths += $path
        Set-Content $path 'mock executable'
        Set-Item -Path ('Function:global:'+$path) -Value {
            $global:LASTEXITCODE=0
            if ($args -contains '-dumpmachine') { $global:CompilerTestTarget }
            elseif ($args -contains '-print-file-name=libucrt.a') { $global:CompilerTestLibrary }
            else { 'clang 20' }
        }
    }
    . (Join-Path $project 'script/windows-compiler.ps1')
    $env:CFLAGS='-O1'
    $env:CXXFLAGS='-O3'
    foreach ($name in @('CFLAGS_x86_64-pc-windows-msvc','CXXFLAGS_x86_64-pc-windows-msvc','CXXFLAGS_x86_64_pc_windows_msvc')) { [Environment]::SetEnvironmentVariable($name,$null,'Process') }
    $env:CFLAGS_x86_64_pc_windows_msvc='-O2 --target=x86_64-pc-windows-msvc'
    Initialize-WindowsCompiler
    Initialize-WindowsCompiler
    if ($env:CC -ne $driverPaths[0] -or $env:CXX -ne $driverPaths[1]) { throw 'Wrong compiler path with spaces' }
    if ($env:CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER -ne $env:CC -or $env:RUSTUP_TOOLCHAIN -ne 'stable-x86_64-pc-windows-gnullvm') { throw 'Wrong Rust host/linker selection' }
    if ($env:CFLAGS_x86_64_pc_windows_msvc -ne '-O2 --target=x86_64-pc-windows-msvc --target=x86_64-w64-windows-gnu') { throw 'GNU target override is not last or not idempotent' }
    if ($env:CXXFLAGS_x86_64_pc_windows_msvc -ne '-O3 --target=x86_64-w64-windows-gnu') { throw 'Generic CXXFLAGS were not preserved' }
    if ([Environment]::GetEnvironmentVariable('CFLAGS_x86_64-pc-windows-msvc','Process') -ne '-O1 --target=x86_64-w64-windows-gnu') { throw 'Generic CFLAGS were not preserved' }
    $before = @{}
    foreach ($name in $names) { $before[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
    & (Join-Path $project 'script/check-tools-windows.ps1')
    foreach ($name in $names) { if ([string]$before[$name] -ne [string][Environment]::GetEnvironmentVariable($name,'Process')) { throw "Checker changed $name" } }
    $global:CompilerTestRustHost='x86_64-pc-windows-msvc'
    $rejected=$false
    try { & (Join-Path $project 'script/check-tools-windows.ps1') } catch { $rejected=$true }
    if (-not $rejected) { throw 'MSVC Rust host accepted' }
    $global:CompilerTestTarget='x86_64-pc-windows-msvc'
    $env:CC='preserve on failure'
    $rejected=$false
    try { Initialize-WindowsCompiler } catch { $rejected=$true }
    if (-not $rejected -or $env:CC -ne 'preserve on failure') { throw 'Wrong target accepted or failed initialization mutated selection' }
    $global:CompilerTestTarget='x86_64-w64-windows-gnu'
    Remove-Item $global:CompilerTestLibrary
    $rejected=$false
    try { Initialize-WindowsCompiler } catch { $rejected=$true }
    if (-not $rejected) { throw 'Missing UCRT library accepted' }
    Write-Output 'PASS: LLVM-MinGW resolver, spaced paths, GNU parser flags, Rust host/linker, read-only checks and failure handling (mocked)'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name,$saved[$name],'Process') }
    foreach ($name in ($toolNames + @('nvim.exe','tree-sitter.exe','fzf.exe','rustc.exe','rustup.exe') + $driverPaths)) { Remove-Item -LiteralPath ('Function:'+$name) -ErrorAction SilentlyContinue }
    Remove-Variable CompilerTestLibrary,CompilerTestTarget,CompilerTestRustHost -Scope Global -ErrorAction SilentlyContinue
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
}
