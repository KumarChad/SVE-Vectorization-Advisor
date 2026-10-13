// AI/HPC kernels used as test subjects for the SveVectorizeHint pass.
//
// These are the loop shapes that dominate AI workloads: dense matrix
// multiply (GEMM - every Linear/attention layer) and 2-D convolution
// (every CNN layer). `restrict` tells the compiler the arrays don't
// overlap, which is true here and is what real BLAS/ML kernels assume.

#include "kernels.h"

// Textbook i-j-k GEMM: C = A * B, all n x n, row-major.
// The innermost k-loop is a reduction that walks B down a *column*
// (stride n), which is hard to vectorize with fixed-width NEON.
void gemm_naive(int n, const float *restrict A, const float *restrict B,
                float *restrict C) {
  for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++) {
      float acc = 0.0f;
      for (int k = 0; k < n; k++)
        acc += A[i * n + k] * B[k * n + j];
      C[i * n + j] = acc;
    }
}

// Cache-blocked (tiled) GEMM with i-k-j loop order inside each tile.
// Tiling keeps a TILE x TILE block of B hot in L1/L2 cache, and the
// i-k-j order makes the innermost loop walk B and C *contiguously* -
// the classic transformation behind every fast BLAS library.
void gemm_tiled(int n, const float *restrict A, const float *restrict B,
                float *restrict C) {
  for (int i = 0; i < n * n; i++)
    C[i] = 0.0f;

  for (int ii = 0; ii < n; ii += TILE)
    for (int kk = 0; kk < n; kk += TILE)
      for (int jj = 0; jj < n; jj += TILE) {
        int imax = ii + TILE < n ? ii + TILE : n;
        int kmax = kk + TILE < n ? kk + TILE : n;
        int jmax = jj + TILE < n ? jj + TILE : n;
        for (int i = ii; i < imax; i++)
          for (int k = kk; k < kmax; k++) {
            float a = A[i * n + k];
            for (int j = jj; j < jmax; j++)
              C[i * n + j] += a * B[k * n + j];
          }
      }
}

// 2-D convolution, single channel, "valid" padding:
// out is (h-kh+1) x (w-kw+1).
void conv2d(int h, int w, int kh, int kw, const float *restrict in,
            const float *restrict kern, float *restrict out) {
  int oh = h - kh + 1, ow = w - kw + 1;
  for (int y = 0; y < oh; y++)
    for (int x = 0; x < ow; x++) {
      float acc = 0.0f;
      for (int dy = 0; dy < kh; dy++)
        for (int dx = 0; dx < kw; dx++)
          acc += in[(y + dy) * w + (x + dx)] * kern[dy * kw + dx];
      out[y * ow + x] = acc;
    }
}
