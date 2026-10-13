# sve-vectorize-hint

**A target-aware vectorization policy pass for Arm SVE, built as an out-of-tree LLVM 18 plugin and evaluated on NVIDIA Grace (Neoverse V2) and AWS Graviton3 (Neoverse V1).**

LLVM's loop vectorizer makes two decisions that matter a lot on SVE machines: *NEON or SVE?* and *may this floating-point reduction be reordered?* This pass analyses each loop (ScalarEvolution stride analysis, reduction detection, the target's real vector width from TargetTransformInfo) and steers both decisions per loop. One flag, same source, and it does the right thing on both CPUs:

| kernel | CPU | `clang -O3` | `-ffast-math` (whole file) | `gcc-13 -O3` | **this pass (relaxed)** |
|---|---|---:|---:|---:|---:|
| naive GEMM | Grace (128-bit SVE) | 1.00x | 1.91x | 1.31x | **1.91x** — reassociates *one* loop, not the whole file |
| tiled GEMM | Grace (128-bit SVE) | 1.00x | 0.85x | 1.17x | **1.00x** — avoids the SVE slowdown `-ffast-math` walks into |
| naive GEMM | Graviton3 (256-bit SVE) | 1.00x | 1.95x | 2.87x | **5.45x** — SVE gathers + scoped reassociation |

In **strict** mode (the default) the pass never changes a single result bit; all its decisions are bit-exact at every SVE vector length from 128 to 2048 bits.

Speedups are *estimated cycles* (exact per-block execution counts from a QEMU trace × llvm-mca's per-CPU scheduling model) — see [Methodology](#methodology) and [Limitations](#limitations). Full tables: [`results/results.md`](results/results.md).

---

## The problem

**1. Forcing SVE is not automatically a win.** On Grace, SVE registers are 128 bits — the same width as NEON. For a plain contiguous loop, NEON can use load/store-*pair* instructions (`ldp`/`stp`, two vectors per instruction); SVE at this width can't. Same loop, Neoverse V2 model:

```
NEON (clang -O3 default) — 1.73 cycles/iter       SVE (forced) — 2.05 cycles/iter
  ldp   q2, q3, [x9, #-0x10]                         ld1w  { z2.s }, p0/z, [x10, x9, lsl #2]
  ldp   q4, q5, [x28]                                ld1w  { z3.s }, p0/z, [x18, x9, lsl #2]
  fmla  v5.4s, v3.4s, v1.4s                          ld1w  { z4.s }, p0/z, [x27, x9, lsl #2]
  fmla  v4.4s, v2.4s, v1.4s                          fmad  z2.s, p0/m, z1.s, z4.s
  stp   q4, q5, [x28], #0x20                         ld1w  { z5.s }, p0/z, [x28, x9, lsl #2]
  ...                                                fmad  z3.s, p0/m, z1.s, z5.s
                                                     st1w  { z2.s }, p0, [x27, x9, lsl #2]
                                                     st1w  { z3.s }, p0, [x28, x9, lsl #2]
```

On Graviton3 (256-bit SVE), SVE vectors are *twice* as wide as NEON, and the tradeoff flips.

**2. FP reductions are serialised by default.** `acc += a[i] * b[i]` can't be vectorized or split into partial sums without reordering additions, which changes rounding. Without `-ffast-math`, LLVM keeps source order and the loop runs at the speed of the FMA latency chain. `-ffast-math` fixes that, but for the **entire translation unit** — and it also implies `nnan`/`ninf`, which lets the compiler delete `isnan()` checks elsewhere in the file.

## What the pass does

For every innermost loop, right before LLVM's loop vectorizer runs:

**Analysis**
- **Shape**: rejects loops with opaque calls, switches or indirect branches.
- **Access patterns** (ScalarEvolution): every load/store classified as *unit-stride*, *strided* (needs SVE gather/scatter — NEON has none), or *loop-invariant*. Anything SCEV can't analyse is left alone.
- **FP reductions** (`RecurrenceDescriptor::isReductionPHI`).
- **Target vector widths** (TargetTransformInfo): NEON width vs. `SVE minimum width × getVScaleForTuning()` — i.e. what the CPU actually implements (Neoverse V2: 128 bits, V1: 256 bits).

**Policy**

| loop | strict (default) | relaxed |
|---|---|---|
| contiguous, no FP reduction | force SVE **iff SVE is wider than NEON** | same |
| FP reduction | leave alone (bit-exact) | set `reassoc` on the reduction chain only ("scoped fast-math"), let LLVM's cost model choose |
| needs gathers | leave alone | force SVE **iff SVE is wider than NEON** (`-sve-hint-gathers=auto`) |
| calls / unanalysable | leave alone | leave alone |

"Force SVE" means attaching the loop metadata LLVM's vectorizer already understands (`llvm.loop.vectorize.enable`, `llvm.loop.vectorize.scalable.enable`, `llvm.loop.vectorize.width`). The pass changes only metadata and fast-math flags, never the CFG.

A subtle point the pass handles: **an explicit vectorize hint is itself permission to reorder FP math** (`LoopVectorizeHints::allowReordering()`). A naive "always force SVE" pass would silently change numerical results. Strict mode therefore refuses to hint any FP-reduction loop.

Every decision is explained in a log line (`results/pass_log.txt`):

```
gemm_tiled @ kernels.c:42 [unit=3 strided=0 fp-red=0 | NEON=128b SVE=128b] -> leave width to cost model (SVE no wider than NEON here; NEON ldp/stp is cheaper)
gemm_tiled @ kernels.c:42 [unit=3 strided=0 fp-red=0 | NEON=128b SVE=256b] -> FORCE SVE (SVE is wider than NEON on this CPU)
gemm_naive @ kernels.c:18 [unit=1 strided=1 fp-red=1 | NEON=128b SVE=128b] -> reassoc(1 ops); leave width to cost model (needs gathers; at this SVE width they lose to scalar code)
gemm_naive @ kernels.c:18 [unit=1 strided=1 fp-red=1 | NEON=128b SVE=256b] -> reassoc(1 ops); FORCE SVE (SVE gathers (NEON has none))
```

## Key findings

1. **Scoped reassociation matches `-ffast-math` exactly where it matters.** On Grace, naive GEMM with the pass produces *the same* dynamic instruction count as whole-file `-ffast-math` (4,139,253) and the same 1.91x — but with every other loop in the file keeping IEEE semantics.
2. **"Always use SVE" is wrong on Grace.** Forcing SVE on the tiled GEMM costs **15%** (0.85x). Interestingly, `-ffast-math` makes LLVM's *own* cost model choose SVE for that loop and lose the same 15%; the pass avoids it.
3. **Gathers flip from loss to big win with vector width.** Naive GEMM with SVE gathers: 1.74x on Grace (worse than scalar with split accumulators, 1.91x) but **5.45x** on Graviton3. The `auto` gather policy encodes exactly that.
4. **Where the pass doesn't help, it says so.** On `conv2d` nothing beats baseline meaningfully: the vectorizable dimension is the output width, not the 3-tap inner loop LLVM sees. That needs outer-loop vectorization / loop interchange — out of scope (see Future work). GCC also edges out clang on the tiled GEMM (1.17x–1.22x) with fewer instructions — worth investigating.
5. **Why GCC isn't bit-exact without fast-math:** it vectorizes the reduction with SVE's *ordered* `fadda`, which preserves summation order but requires a separate `fmul`, so products are rounded before the add instead of being fused like the scalar reference.

## Methodology

`python3 bench/run_bench.py` does everything (≈5 min):

1. **Variants**: `clang -O3`, the pass (strict / relaxed / relaxed with gathers off / force-SVE-everywhere), `clang -O3 -ffast-math`, `gcc-13 -O3` — each for `-mcpu=neoverse-v2` and `-mcpu=neoverse-v1`.
2. **Correctness**: each kernel runs under `qemu-aarch64` at SVE vector lengths **128, 256, 512 and 2048 bits** and is compared to a scalar reference built with vectorization disabled. The run fails if relative error exceeds 1e-4 (observed worst case: 3.0e-7). Bit-exactness is reported separately.
3. **Exact profile**: QEMU runs each kernel at the target CPU's vector length (128 for Grace, 256 for Graviton3) with one-instruction-per-block tracing, giving the execution count of every instruction.
4. **Cycle estimate**: the kernel is split into basic blocks; `llvm-mca` (`-mcpu=neoverse-v2` / `neoverse-v1`) gives each block's steady-state cycles; total = Σ exec_count × cycles. This is the profile-weighted static throughput approach used by tools like BHive and uiCA.

**An llvm-mca modelling artifact, found and corrected.** Initially llvm-mca reported 12 cycles/iteration for the NEON tiled-GEMM loop despite a resource bound of 1.3. The timeline showed why: it makes the base-register writeback of a post-indexed store (`stp q4, q5, [x28], #32`) wait for the *store data*, creating a fake loop-carried chain load → FMA → store → pointer → next load (6+4+2 = 12 cycles). Real cores compute the writeback in the address unit, independent of store data. The benchmark rewrites pre/post-indexed accesses into a plain access plus an explicit `add` before calling llvm-mca, which keeps true dependencies (such as an FP accumulator chain) and removes only the fake one.

## Limitations

- **No real Grace hardware.** Cycles are estimates from LLVM's scheduling models, which are good but not perfect.
- **No cache modelling.** llvm-mca treats every load as an L1 hit, so the main benefit of tiling (cache reuse) is not captured; at size 96 the working set fits in L2 anyway.
- **Small kernel set** (3 kernels, one size). The "SVE wider than NEON" rule is a heuristic derived from these measurements; a production version should ask the target's cost model directly (e.g. `TTI::getGatherScatterOpCost`).
- QEMU timing is never used for performance — only for correctness and instruction counts.

## Layout

```
src/pass/SveVectorizeHint.cpp   the LLVM pass (analysis + policy + plugin registration)
src/kernels/kernels.c           naive GEMM, cache-tiled GEMM, 3x3 conv2d (the test subjects)
src/kernels/reference.c         scalar ground truth (built with vectorization off)
src/kernels/harness.c           runs one kernel, checks against reference, reports SVE vector length
bench/run_bench.py              build -> correctness -> profile -> llvm-mca -> results/
test/policy.ll                  lit + FileCheck regression tests for every policy cell
results/                        results.md, results.json, pass_log.txt, generated assembly
```

## Setup (Ubuntu 24.04, or WSL on Windows)

```bash
sudo apt install clang llvm-18-dev cmake qemu-user gcc-aarch64-linux-gnu libc6-dev-arm64-cross python3-pip
pip install --break-system-packages lit
```

On Windows: `wsl --install -d Ubuntu-24.04`, then run the above inside WSL.

## Build, test, run

```bash
cmake -S . -B build -DLLVM_DIR=$(llvm-config-18 --cmakedir) -DCMAKE_CXX_COMPILER=clang++
cmake --build build

lit -v test/                      # regression tests
python3 bench/run_bench.py        # full benchmark -> results/results.md
```

Use the pass on your own code:

```bash
P=build/libSveVectorizeHint.so
clang --target=aarch64-linux-gnu -mcpu=neoverse-v2 -O3 -fplugin=$P -fpass-plugin=$P \
      -mllvm -sve-hint-mode=relaxed  your_file.c -S -o out.s
# or on IR:
opt-18 -load $P -load-pass-plugin $P -mtriple=aarch64-linux-gnu -mcpu=neoverse-v2 \
       -passes=loop-simplify,sve-vectorize-hint -S in.ll
```

Options: `-sve-hint-mode=strict|relaxed`, `-sve-hint-gathers=auto|on|off`, `-sve-hint-force-scalable`, `-sve-hint-quiet`. (`-fplugin` is needed alongside `-fpass-plugin` so clang registers the pass's `-mllvm` options before parsing them.)

## Future work

- Outer-loop vectorization / interchange for convolution (vectorize over output width).
- Replace the width heuristic with direct TTI cost queries for gathers.
- Validate on real Grace hardware with `perf stat`.
- Investigate why GCC's tiled-GEMM code beats clang's by ~17–22%.
