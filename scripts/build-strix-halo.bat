@echo off
REM Build helper for AMD Strix Halo / Ryzen AI Max+ (e.g. Ryzen AI Max+ 395)
REM on Windows. Combines AVX-512 (Zen5, full width incl. VNNI / VBMI / BF16)
REM with HIPBLAS for the integrated Radeon 8060S iGPU (RDNA 3.5, gfx1151).
REM
REM GGML_HIP_UMA=ON keeps weights / KV cache in shared system memory rather
REM than duplicating them on a separate device, which is what you want on an
REM APU. See docs\build.md ("AMD Strix Halo / Ryzen AI Max+ (gfx1151)").
REM
REM Requirements:
REM   - ROCm / HIP SDK for Windows (HIP_PATH set, hipcc + clang on PATH).
REM   - x64 Native Tools Command Prompt for VS, or a shell where clang from
REM     the HIP SDK is on PATH.
REM
REM Usage:
REM   scripts\build-strix-halo.bat [build-dir]
REM
REM Override the GPU target if your toolchain reports a different arch:
REM   set AMDGPU_TARGETS=gfx1150
REM   scripts\build-strix-halo.bat

setlocal

if "%~1"=="" (set BUILD_DIR=build) else (set BUILD_DIR=%~1)
if "%AMDGPU_TARGETS%"=="" set AMDGPU_TARGETS=gfx1151

if not "%HIP_PATH%"=="" set PATH=%HIP_PATH%\bin;%PATH%

cmake -S . -B "%BUILD_DIR%" -G Ninja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_C_COMPILER=clang ^
    -DCMAKE_CXX_COMPILER=clang++ ^
    -DGGML_NATIVE=ON ^
    -DGGML_AVX512=ON ^
    -DGGML_AVX512_VBMI=ON ^
    -DGGML_AVX512_VNNI=ON ^
    -DGGML_AVX512_BF16=ON ^
    -DGGML_HIPBLAS=ON ^
    -DGGML_HIP_UMA=ON ^
    -DAMDGPU_TARGETS=%AMDGPU_TARGETS% ^
    -DCMAKE_HIP_ARCHITECTURES=%AMDGPU_TARGETS%
if errorlevel 1 exit /b 1

cmake --build "%BUILD_DIR%" --config Release
