# Results (problem size 96)

* **est. cycles** = sum over the kernel's basic blocks of (exact execution count, from a QEMU instruction trace) x (llvm-mca steady-state cycles for that block on the target CPU's scheduling model). Excludes cache misses - every load is modelled as an L1 hit.
* **speedup** is relative to `clang -O3` on the same CPU.
* **max rel. error** vs. a strictly in-order scalar reference, worst case over SVE vector lengths 128/256/512/2048 bits.
* **hot loop** = vector ISA used by the block with the most estimated cycles.

## NVIDIA Grace (`-mcpu=neoverse-v2`, 128-bit SVE)

### gemm_naive

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | scalar | 3,226,772 | 1,803,848 | **1.00x** | 0.0e+00 | yes |
| +pass strict | scalar | 3,226,772 | 1,803,848 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | scalar | 4,139,253 | 945,716 | **1.91x** | 3.0e-07 | no |
| +pass relaxed, gathers=off | scalar | 4,139,253 | 945,716 | **1.91x** | 3.0e-07 | no |
| +pass relaxed, force SVE everywhere | SVE | 2,489,402 | 1,039,447 | **1.74x** | 3.0e-07 | no |
| clang -O3 -ffast-math | scalar | 4,139,253 | 945,670 | **1.91x** | 3.0e-07 | no |
| gcc-13 -O3 | SVE | 1,871,441 | 1,372,556 | **1.31x** | 2.6e-07 | no |

### gemm_tiled

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | NEON | 1,504,452 | 262,374 | **1.00x** | 0.0e+00 | yes |
| +pass strict | NEON | 1,504,452 | 262,374 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | NEON | 1,504,452 | 262,374 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed, gathers=off | NEON | 1,504,452 | 262,374 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed, force SVE everywhere | SVE | 1,726,251 | 309,341 | **0.85x** | 0.0e+00 | yes |
| clang -O3 -ffast-math | SVE | 1,726,251 | 309,341 | **0.85x** | 0.0e+00 | yes |
| gcc-13 -O3 | NEON | 1,362,775 | 223,337 | **1.17x** | 0.0e+00 | yes |

### conv2d

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | scalar | 1,052,464 | 263,428 | **1.00x** | 0.0e+00 | yes |
| +pass strict | scalar | 1,052,464 | 263,428 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | scalar | 1,061,297 | 264,753 | **0.99x** | 0.0e+00 | yes |
| +pass relaxed, gathers=off | scalar | 1,061,297 | 264,753 | **0.99x** | 0.0e+00 | yes |
| +pass relaxed, force SVE everywhere | scalar | 1,061,297 | 264,753 | **0.99x** | 0.0e+00 | yes |
| clang -O3 -ffast-math | scalar | 1,158,498 | 270,321 | **0.97x** | 0.0e+00 | yes |
| gcc-13 -O3 | SVE | 636,870 | 254,621 | **1.03x** | 1.4e-07 | no |

## AWS Graviton3 (`-mcpu=neoverse-v1`, 256-bit SVE)

### gemm_naive

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | scalar | 3,226,772 | 3,575,206 | **1.00x** | 0.0e+00 | yes |
| +pass strict | scalar | 3,226,772 | 3,575,206 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | SVE | 1,457,208 | 656,526 | **5.45x** | 3.0e-07 | no |
| +pass relaxed, gathers=off | scalar | 4,139,253 | 1,829,536 | **1.95x** | 3.0e-07 | no |
| +pass relaxed, force SVE everywhere | SVE | 1,457,208 | 656,526 | **5.45x** | 3.0e-07 | no |
| clang -O3 -ffast-math | scalar | 4,139,253 | 1,829,536 | **1.95x** | 3.0e-07 | no |
| gcc-13 -O3 | SVE | 986,705 | 1,244,843 | **2.87x** | 2.6e-07 | no |

### gemm_tiled

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| +pass strict | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed, gathers=off | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed, force SVE everywhere | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| clang -O3 -ffast-math | SVE | 1,117,996 | 277,486 | **1.00x** | 0.0e+00 | yes |
| gcc-13 -O3 | SVE | 861,774 | 227,565 | **1.22x** | 0.0e+00 | yes |

### conv2d

| variant | hot loop | dyn. instructions | est. cycles | speedup | max rel. error | bit-exact |
|---|---|---:|---:|---:|---:|:---:|
| clang -O3 | scalar | 1,052,462 | 436,441 | **1.00x** | 0.0e+00 | yes |
| +pass strict | scalar | 1,052,462 | 436,441 | **1.00x** | 0.0e+00 | yes |
| +pass relaxed (default policy) | scalar | 1,158,497 | 438,696 | **0.99x** | 0.0e+00 | yes |
| +pass relaxed, gathers=off | scalar | 1,158,497 | 438,696 | **0.99x** | 0.0e+00 | yes |
| +pass relaxed, force SVE everywhere | scalar | 1,158,497 | 438,696 | **0.99x** | 0.0e+00 | yes |
| clang -O3 -ffast-math | scalar | 1,052,464 | 436,441 | **1.00x** | 0.0e+00 | yes |
| gcc-13 -O3 | SVE | 636,870 | 390,457 | **1.12x** | 1.4e-07 | no |

