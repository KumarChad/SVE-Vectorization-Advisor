#ifndef SVE_VEC_KERNELS_H
#define SVE_VEC_KERNELS_H

// Tile edge for the cache-blocked GEMM. 32x32 floats = 4 KiB per tile,
// so a tile of A, B and C together sit comfortably in a 64 KiB L1D
// (Neoverse V2 has 64 KiB L1D per core).
#define TILE 32

void gemm_naive(int n, const float *restrict A, const float *restrict B,
                float *restrict C);
void gemm_tiled(int n, const float *restrict A, const float *restrict B,
                float *restrict C);
void conv2d(int h, int w, int kh, int kw, const float *restrict in,
            const float *restrict kern, float *restrict out);

// Scalar, strictly in-order reference implementations (reference.c is
// always compiled with vectorization disabled).
void ref_gemm(int n, const float *A, const float *B, float *C);
void ref_conv2d(int h, int w, int kh, int kw, const float *in,
                const float *kern, float *out);

#endif
