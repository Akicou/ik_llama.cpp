#!/bin/sh
# Build helper for AMD Strix Halo / Ryzen AI Max+ (e.g. Ryzen AI Max+ 395).
#
# Strix Halo combines a Zen5 CPU (full-width AVX-512 incl. VNNI / VBMI / BF16)
# with a Radeon 8060S iGPU based on RDNA 3.5 (LLVM target gfx1151). Because
# the iGPU shares system memory with the CPU, builds for this platform should
# be configured with HIPBLAS + GGML_HIP_UMA so weights and KV cache do not
# have to be duplicated between host and device. The Zen5 cores benefit from
# the same IQK AVX-512 GEMM path used on Zen4 / Sapphire Rapids+ (gated by
# HAVE_FANCY_SIMD; see docs/build.md).
#
# Requirements:
#   - ROCm / HIP SDK installed (hipcc, hipBLAS, rocBLAS).
#   - amdgpu-arch reports gfx1151 (override with AMDGPU_TARGETS=... if needed).
#
# Usage:
#   ./scripts/build-strix-halo.sh [build-dir]
#
# Override the GPU target if your toolchain reports a different arch:
#   AMDGPU_TARGETS=gfx1150 ./scripts/build-strix-halo.sh
#
# Override ROCm location if it is not at /opt/rocm:
#   ROCM_PATH=/usr ./scripts/build-strix-halo.sh

set -e

BUILD_DIR=${1:-build}
AMDGPU_TARGETS=${AMDGPU_TARGETS:-gfx1151}

if [ -n "$ROCM_PATH" ]; then
    PREFIX_PATH="$ROCM_PATH;$ROCM_PATH/lib/cmake;$ROCM_PATH/lib64/cmake"
    HIPCXX_DEFAULT="$ROCM_PATH/llvm/bin/clang++"
elif [ -d /opt/rocm ]; then
    PREFIX_PATH="/opt/rocm;/opt/rocm/lib/cmake;/opt/rocm/lib64/cmake"
    HIPCXX_DEFAULT="/opt/rocm/llvm/bin/clang++"
else
    PREFIX_PATH=""
    HIPCXX_DEFAULT=""
fi

# Allow caller-provided HIPCXX / CMAKE_HIP_COMPILER to take precedence.
if [ -z "$HIPCXX" ] && [ -n "$HIPCXX_DEFAULT" ] && [ -x "$HIPCXX_DEFAULT" ]; then
    HIPCXX="$HIPCXX_DEFAULT"
fi

CMAKE_ARGS="-B $BUILD_DIR \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_NATIVE=ON \
    -DGGML_AVX512=ON \
    -DGGML_AVX512_VBMI=ON \
    -DGGML_AVX512_VNNI=ON \
    -DGGML_AVX512_BF16=ON \
    -DGGML_HIPBLAS=ON \
    -DGGML_HIP_UMA=ON \
    -DAMDGPU_TARGETS=$AMDGPU_TARGETS \
    -DCMAKE_HIP_ARCHITECTURES=$AMDGPU_TARGETS"

if [ -n "$PREFIX_PATH" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PREFIX_PATH=$PREFIX_PATH"
fi

if [ -n "$HIPCXX" ]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_HIP_COMPILER=$HIPCXX"
fi

# shellcheck disable=SC2086
cmake $CMAKE_ARGS

cmake --build "$BUILD_DIR" --config Release -j
