// Test harness: runs ONE kernel on deterministic pseudo-random data and
// compares it against the scalar reference.
//
//   usage: harness <gemm_naive|gemm_tiled|conv2d> <size>
//
// Prints one machine-readable line:
//   kernel=<k> size=<n> vl_bits=<v> max_abs_err=<e> max_rel_err=<r> bit_exact=<0|1>
//
// Only one kernel runs per process so that an external tool (QEMU's
// execution trace, see bench/run_bench.py) can attribute executed
// instructions to that kernel's address range.

#include "kernels.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned rng_state = 12345u;
static float frand(void) { // xorshift32 -> [-1, 1)
  rng_state ^= rng_state << 13;
  rng_state ^= rng_state >> 17;
  rng_state ^= rng_state << 5;
  return (float)(rng_state >> 8) / (float)(1u << 23) - 1.0f;
}

static float *alloc_rand(size_t count) {
  float *p = aligned_alloc(64, ((count * sizeof(float) + 63) / 64) * 64);
  for (size_t i = 0; i < count; i++)
    p[i] = frand();
  return p;
}

static float *alloc_zero(size_t count) {
  float *p = aligned_alloc(64, ((count * sizeof(float) + 63) / 64) * 64);
  memset(p, 0, count * sizeof(float));
  return p;
}

static int vector_length_bits(void) {
#if defined(__ARM_FEATURE_SVE)
  long vl;
  __asm__ volatile("rdvl %0, #1" : "=r"(vl)); // bytes per SVE vector
  return (int)(vl * 8);
#else
  return 0;
#endif
}

static void compare(const char *kname, int n, const float *got,
                    const float *ref, size_t count) {
  double max_abs = 0.0, max_ref = 0.0;
  int exact = 1;
  for (size_t i = 0; i < count; i++) {
    double d = fabs((double)got[i] - (double)ref[i]);
    if (d > max_abs)
      max_abs = d;
    if (fabs(ref[i]) > max_ref)
      max_ref = fabs(ref[i]);
    if (memcmp(&got[i], &ref[i], sizeof(float)) != 0)
      exact = 0;
  }
  double rel = max_ref > 0 ? max_abs / max_ref : max_abs;
  printf("kernel=%s size=%d vl_bits=%d max_abs_err=%.3e max_rel_err=%.3e "
         "bit_exact=%d\n",
         kname, n, vector_length_bits(), max_abs, rel, exact);
  // Relative error budget: well inside what ML workloads tolerate
  // (they routinely run in bf16 / tf32 with ~1e-3 relative error).
  if (rel > 1e-4) {
    fprintf(stderr, "FAIL: %s error %.3e exceeds 1e-4\n", kname, rel);
    exit(1);
  }
}

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "usage: %s <gemm_naive|gemm_tiled|conv2d> <size>\n",
            argv[0]);
    return 2;
  }
  const char *k = argv[1];
  int n = atoi(argv[2]);

  if (!strcmp(k, "gemm_naive") || !strcmp(k, "gemm_tiled")) {
    float *A = alloc_rand((size_t)n * n), *B = alloc_rand((size_t)n * n);
    float *C = alloc_zero((size_t)n * n), *R = alloc_zero((size_t)n * n);
    if (k[5] == 'n')
      gemm_naive(n, A, B, C);
    else
      gemm_tiled(n, A, B, C);
    ref_gemm(n, A, B, R);
    compare(k, n, C, R, (size_t)n * n);
  } else if (!strcmp(k, "conv2d")) {
    const int kh = 3, kw = 3; // the ubiquitous 3x3 CNN filter
    float *in = alloc_rand((size_t)n * n), *kern = alloc_rand(kh * kw);
    size_t outn = (size_t)(n - kh + 1) * (n - kw + 1);
    float *out = alloc_zero(outn), *R = alloc_zero(outn);
    conv2d(n, n, kh, kw, in, kern, out);
    ref_conv2d(n, n, kh, kw, in, kern, R);
    compare(k, n, out, R, outn);
  } else {
    fprintf(stderr, "unknown kernel %s\n", k);
    return 2;
  }
  return 0;
}
