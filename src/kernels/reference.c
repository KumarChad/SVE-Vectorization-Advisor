// Scalar reference implementations. Build this file with
// -fno-vectorize -fno-slp-vectorize so its floating-point additions
// happen in exactly source order - the "ground truth" every optimized
// variant is compared against.

#include "kernels.h"

void ref_gemm(int n, const float *A, const float *B, float *C) {
  for (int i = 0; i < n; i++)
    for (int j = 0; j < n; j++) {
      float acc = 0.0f;
      for (int k = 0; k < n; k++)
        acc += A[i * n + k] * B[k * n + j];
      C[i * n + j] = acc;
    }
}

void ref_conv2d(int h, int w, int kh, int kw, const float *in,
                const float *kern, float *out) {
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
