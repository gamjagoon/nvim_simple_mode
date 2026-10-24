# LLVM-MinGW selection shared by the installers and read-only prerequisite checker.
function Get-WindowsCompiler {
    $names = @('x86_64-w64-mingw32-clang.exe', 'x86_64-w64-mingw32-clang++.exe')
    $drivers = @()
    foreach ($name in $names) {
        if ($env:LLVM_MINGW_ROOT) {
            $driver = Join-Path (Join-Path $env:LLVM_MINGW_ROOT 'bin') $name
            if (-not (Test-Path -LiteralPath $driver -PathType Leaf)) { throw "LLVM-MinGW driver is missing: $driver" }
        } else {
            $found = Get-Command $name -ErrorAction SilentlyContinue
            if (-not $found) { throw "LLVM-MinGW driver $name is missing. Install LLVM-MinGW UCRT x64 or set LLVM_MINGW_ROOT." }
            $driver = $found.Source
            if (-not $driver) { $driver = $found.Name }
        }
        $target = & $driver -dumpmachine
        if ($LASTEXITCODE -ne 0 -or ([string]($target | Select-Object -Last 1)).Trim() -notmatch '^x86_64-w64-(windows-gnu|mingw32)$') {
            throw "LLVM-MinGW x64 GNU target verification failed: $driver"
        }
        $drivers += $driver
    }
    $ucrt = & ($drivers[0]) '-print-file-name=libucrt.a'
    if ($LASTEXITCODE -ne 0 -or -not $ucrt -or -not (Test-Path -LiteralPath ([string]($ucrt | Select-Object -Last 1)).Trim() -PathType Leaf)) {
        throw 'LLVM-MinGW UCRT import library libucrt.a was not found.'
    }
    return @{ CC = $drivers[0]; CXX = $drivers[1] }
}

function Initialize-WindowsCompiler {
    $drivers = Get-WindowsCompiler
    $env:CC = $drivers.CC
    $env:CXX = $drivers.CXX
    if ($env:LLVM_MINGW_ROOT) {
        $bin = Join-Path $env:LLVM_MINGW_ROOT 'bin'
        if (($env:PATH -split ';') -notcontains $bin) { $env:PATH = $bin + ';' + $env:PATH }
    }
    foreach ($target in @('x86_64-pc-windows-msvc', 'x86_64_pc_windows_msvc', 'x86_64-pc-windows-gnullvm', 'x86_64_pc_windows_gnullvm')) {
        [Environment]::SetEnvironmentVariable('CC_' + $target, $env:CC, 'Process')
        [Environment]::SetEnvironmentVariable('CXX_' + $target, $env:CXX, 'Process')
    }
    # The distributed tree-sitter CLI is MSVC-hosted. cc-rs appends these user
    # flags after its inferred MSVC target; build parser DLLs with the GNU CRT.
    foreach ($target in @('x86_64-pc-windows-msvc', 'x86_64_pc_windows_msvc')) {
        foreach ($prefix in @('CFLAGS_', 'CXXFLAGS_')) {
            $name = $prefix + $target
            $flags = [Environment]::GetEnvironmentVariable($name, 'Process')
            if ([string]::IsNullOrEmpty($flags)) { $flags = [Environment]::GetEnvironmentVariable($prefix.TrimEnd('_'), 'Process') }
            $flags = ($flags -replace '(?:\s|^)--target=x86_64-w64-windows-gnu(?=\s|$)', '').Trim()
            [Environment]::SetEnvironmentVariable($name, ($flags + ' --target=x86_64-w64-windows-gnu').Trim(), 'Process')
        }
    }
    $env:CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER = $env:CC
    $env:RUSTUP_TOOLCHAIN = 'stable-x86_64-pc-windows-gnullvm'
    Write-Host 'Selected LLVM-MinGW UCRT x64 and Rust windows-gnullvm for this process.'
}
