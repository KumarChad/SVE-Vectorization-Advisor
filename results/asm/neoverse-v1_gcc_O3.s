	.arch armv8.4-a+crc+sve+profile+rng+ssbs+i8mm+bf16
	.file	"kernels.c"
	.text
	.align	2
	.p2align 5,,15
	.global	gemm_naive
	.type	gemm_naive, %function
gemm_naive:
.LFB0:
	.cfi_startproc
	mov	w4, w0
	mov	x9, x2
	mov	x7, x3
	cmp	w0, 0
	ble	.L1
	sxtw	x3, w0
	cntb	x0
	index	z3.s, #0, w4
	mov	x2, x1
	sbfiz	x8, x4, 2, 32
	whilelo	p1.s, wzr, w4
	mul	x3, x3, x0
	mov	w10, 0
	cntw	x5
	.p2align 5,,15
.L3:
	mov	x6, 0
	.p2align 5,,15
.L6:
	movi	v1.2s, #0
	add	x1, x9, x6
	mov	x0, 0
	mov	p0.b, p1.b
	.p2align 5,,15
.L4:
	ld1w	z0.s, p0/z, [x2, x0, lsl 2]
	ld1w	z2.s, p0/z, [x1, z3.s, sxtw 2]
	add	x0, x0, x5
	fmul	z0.s, p0/m, z0.s, z2.s
	add	x1, x1, x3
	fadda	s1, p0, s1, z0.s
	whilelo	p0.s, w0, w4
	b.any	.L4
	str	s1, [x7, x6]
	add	x6, x6, 4
	cmp	x6, x8
	bne	.L6
	add	w10, w10, 1
	add	x7, x7, x8
	add	x2, x2, x8
	cmp	w4, w10
	bne	.L3
.L1:
	ret
	.cfi_endproc
.LFE0:
	.size	gemm_naive, .-gemm_naive
	.align	2
	.p2align 5,,15
	.global	gemm_tiled
	.type	gemm_tiled, %function
gemm_tiled:
.LFB1:
	.cfi_startproc
	stp	x29, x30, [sp, -176]!
	.cfi_def_cfa_offset 176
	.cfi_offset 29, -176
	.cfi_offset 30, -168
	mov	x29, sp
	stp	x19, x20, [sp, 16]
	.cfi_offset 19, -160
	.cfi_offset 20, -152
	mov	x19, x1
	stp	x23, x24, [sp, 48]
	.cfi_offset 23, -128
	.cfi_offset 24, -120
	mov	w24, w0
	mul	w0, w0, w0
	stp	x25, x26, [sp, 64]
	.cfi_offset 25, -112
	.cfi_offset 26, -104
	mov	x26, x2
	stp	x27, x28, [sp, 80]
	.cfi_offset 27, -96
	.cfi_offset 28, -88
	mov	x27, x3
	cbz	w0, .L13
	ubfiz	x2, x0, 2, 32
	mov	w1, 0
	mov	x0, x3
	bl	memset
.L13:
	cmp	w24, 0
	ble	.L9
	lsl	w0, w24, 1
	lsl	w9, w24, 5
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -136
	.cfi_offset 21, -144
	sbfiz	x20, x0, 2, 32
	sxtw	x28, w24
	ptrue	p1.b, all
	sbfiz	x23, x24, 2, 32
	mov	w3, 0
	mov	w1, 0
	cntw	x21
	mov	x22, x20
.L12:
	mov	w15, w1
	add	w1, w1, 32
	cmp	w1, w24
	csel	w25, w1, w24, le
	cmp	w25, w15
	ble	.L28
	sxtw	x7, w3
	mov	w5, 0
	str	w1, [sp, 124]
	mov	x0, 0
	mov	w17, w15
	add	x16, x19, w3, sxtw 2
	mov	x1, x7
.L29:
	add	w7, w0, 32
	str	w0, [sp, 120]
	cmp	w7, w24
	csel	w7, w7, w24, le
	cmp	w7, w0
	ble	.L25
	mov	w2, -3
	sub	w18, w7, #1
	add	x4, x26, w5, sxtw 2
	sub	w15, w2, w0
	add	w14, w0, 1
	str	x4, [sp, 112]
	mov	x20, 0
	add	x30, x0, 2
	stp	w3, w9, [sp, 128]
	mov	x8, x1
	mov	x12, x16
	stp	x0, x1, [sp, 136]
	add	w15, w15, w7
	add	x2, x0, 4
	lsr	w15, w15, 1
	add	x15, x2, w15, uxtw 1
	str	w5, [sp, 160]
.L24:
	add	w4, w20, 32
	cmp	w4, w24
	csel	w4, w4, w24, le
	cmp	w4, w20
	ble	.L14
	ldr	x1, [sp, 112]
	sub	w4, w4, w20
	add	x0, x27, x8, lsl 2
	lsr	w2, w4, 2
	sub	w10, w4, #1
	str	w17, [sp, 164]
	lsl	x2, x2, 4
	and	w11, w4, -4
	whilelo	p2.s, wzr, w4
	and	w9, w4, 3
	mov	x5, x12
	str	x8, [sp, 152]
	mov	x6, x8
	mov	x3, x20
	str	x12, [sp, 168]
	add	x13, x1, x20, lsl 2
	mov	w1, w17
	mov	x17, x19
	.p2align 5,,15
.L15:
	cmp	w18, w14
	ble	.L43
	mov	x8, x30
	mov	x12, x13
	str	x6, [sp, 96]
	sub	x20, x5, #8
	sub	x19, x5, #4
	str	w25, [sp, 108]
.L17:
	add	x6, x20, x8, lsl 2
	add	x25, x12, x23
	ld1rw	z3.s, p1/z, [x6]
	add	x16, x19, x8, lsl 2
	mov	x6, 0
	mov	p0.b, p2.b
	.p2align 5,,15
.L16:
	ld1w	z1.s, p0/z, [x12, x6, lsl 2]
	ld1w	z0.s, p0/z, [x0, x6, lsl 2]
	fmla	z0.s, p0/m, z1.s, z3.s
	st1w	z0.s, p0, [x0, x6, lsl 2]
	ld1w	z2.s, p0/z, [x25, x6, lsl 2]
	ld1rw	z1.s, p1/z, [x16]
	fmla	z0.s, p0/m, z1.s, z2.s
	st1w	z0.s, p0, [x0, x6, lsl 2]
	add	x6, x6, x21
	whilelo	p0.s, w6, w4
	b.any	.L16
	add	x6, x8, 2
	add	x12, x12, x22
	cmp	x6, x15
	beq	.L44
	mov	x8, x6
	b	.L17
.L44:
	ldr	x6, [sp, 96]
	ldr	w25, [sp, 108]
.L27:
	sxtw	x12, w8
	mul	w8, w24, w8
	add	x8, x3, w8, sxtw
	.p2align 5,,15
.L22:
	ldr	s1, [x5, x12, lsl 2]
	cmp	w10, 2
	bls	.L31
.L21:
	dup	v2.4s, v1.s[0]
	add	x19, x26, x8, lsl 2
	mov	x16, 0
	.p2align 5,,15
.L19:
	ldr	q0, [x0, x16]
	ldr	q3, [x19, x16]
	fmla	v0.4s, v3.4s, v2.4s
	str	q0, [x0, x16]
	add	x16, x16, 16
	cmp	x2, x16
	bne	.L19
	cbz	w9, .L45
	mov	w16, w11
.L18:
	uxtw	x19, w16
	mov	z1.s, s1
	sub	w16, w4, w16
	add	x20, x6, x19
	whilelo	p0.s, wzr, w16
	add	x19, x8, x19
	ld1w	z0.s, p0/z, [x27, x20, lsl 2]
	ld1w	z2.s, p0/z, [x26, x19, lsl 2]
	add	x12, x12, 1
	fmla	z0.s, p0/m, z2.s, z1.s
	st1w	z0.s, p0, [x27, x20, lsl 2]
	add	x8, x8, x28
	cmp	w7, w12
	bgt	.L22
.L20:
	add	w1, w1, 1
	add	x6, x6, x28
	add	x0, x0, x23
	add	x5, x5, x23
	cmp	w25, w1
	bne	.L15
	ldr	x8, [sp, 152]
	mov	x19, x17
	mov	x20, x3
	ldr	x12, [sp, 168]
	ldr	w17, [sp, 164]
.L14:
	add	x20, x20, 32
	add	x8, x8, 32
	cmp	w24, w20
	bgt	.L24
	ldp	x0, x1, [sp, 136]
	mov	x16, x12
	ldp	w3, w9, [sp, 128]
	ldr	w5, [sp, 160]
.L25:
	add	x0, x0, 32
	add	w5, w5, w9
	cmp	w24, w0
	bgt	.L29
	ldr	w1, [sp, 124]
.L28:
	add	w3, w3, w9
	cmp	w1, w24
	blt	.L12
	ldp	x21, x22, [sp, 32]
	.cfi_restore 22
	.cfi_restore 21
.L9:
	ldp	x19, x20, [sp, 16]
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	ldp	x29, x30, [sp], 176
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 27
	.cfi_restore 28
	.cfi_restore 25
	.cfi_restore 26
	.cfi_restore 23
	.cfi_restore 24
	.cfi_restore 19
	.cfi_restore 20
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L45:
	.cfi_def_cfa_offset 176
	.cfi_offset 19, -160
	.cfi_offset 20, -152
	.cfi_offset 21, -144
	.cfi_offset 22, -136
	.cfi_offset 23, -128
	.cfi_offset 24, -120
	.cfi_offset 25, -112
	.cfi_offset 26, -104
	.cfi_offset 27, -96
	.cfi_offset 28, -88
	.cfi_offset 29, -176
	.cfi_offset 30, -168
	add	x12, x12, 1
	add	x8, x8, x28
	cmp	w7, w12
	ble	.L20
	ldr	s1, [x5, x12, lsl 2]
	b	.L21
	.p2align 2,,3
.L31:
	mov	w16, 0
	b	.L18
.L43:
	ldr	w8, [sp, 120]
	b	.L27
	.cfi_endproc
.LFE1:
	.size	gemm_tiled, .-gemm_tiled
	.align	2
	.p2align 5,,15
	.global	conv2d
	.type	conv2d, %function
conv2d:
.LFB2:
	.cfi_startproc
	mov	w10, w1
	subs	w0, w0, w2
	sub	w14, w10, w3
	mov	w9, w2
	mov	w1, w3
	mov	x11, x4
	mov	x12, x5
	add	w2, w14, 1
	bmi	.L46
	cmp	w2, 0
	ble	.L46
	sbfiz	x17, x2, 2, 32
	mov	x13, x6
	whilelo	p1.s, wzr, w3
	add	w16, w0, 1
	sxtw	x14, w14
	mov	w15, 0
	mov	w18, 0
	cntw	x4
.L48:
	mov	x8, 0
	mov	x0, 0
	cmp	w9, 0
	ble	.L55
	.p2align 5,,15
.L53:
	movi	v1.2s, #0
	mov	w7, w15
	mov	w6, 0
	mov	w5, 0
	.p2align 5,,15
.L56:
	cmp	w1, 0
	ble	.L52
	add	x2, x8, w7, sxtw
	add	x2, x11, x2, lsl 2
	mov	x0, 0
	add	x3, x12, w6, sxtw 2
	mov	p0.b, p1.b
	.p2align 5,,15
.L49:
	ld1w	z0.s, p0/z, [x2, x0, lsl 2]
	ld1w	z2.s, p0/z, [x3, x0, lsl 2]
	add	x0, x0, x4
	fmul	z0.s, p0/m, z0.s, z2.s
	fadda	s1, p0, s1, z0.s
	whilelo	p0.s, w0, w1
	b.any	.L49
.L52:
	add	w5, w5, 1
	add	w7, w7, w10
	add	w6, w6, w1
	cmp	w9, w5
	bne	.L56
	str	s1, [x13, x8, lsl 2]
	add	x0, x8, 1
	cmp	x14, x8
	beq	.L54
	mov	x8, x0
	b	.L53
.L55:
	cmp	x14, x0
	str	wzr, [x13, x0, lsl 2]
	add	x0, x0, 1
	bne	.L55
.L54:
	add	w18, w18, 1
	add	x13, x13, x17
	add	w15, w15, w10
	cmp	w18, w16
	bne	.L48
.L46:
	ret
	.cfi_endproc
.LFE2:
	.size	conv2d, .-conv2d
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
