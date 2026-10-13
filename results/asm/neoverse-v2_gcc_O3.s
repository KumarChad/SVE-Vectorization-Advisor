	.arch armv9-a+crc+profile+rng+memtag+sve2-bitperm+i8mm+bf16
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
	whilelo	p1.s, wzr, w4
	mov	x2, x1
	sbfiz	x8, x4, 2, 32
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
	stp	x29, x30, [sp, -192]!
	.cfi_def_cfa_offset 192
	.cfi_offset 29, -192
	.cfi_offset 30, -184
	mov	x29, sp
	stp	x23, x24, [sp, 48]
	.cfi_offset 23, -144
	.cfi_offset 24, -136
	mov	w23, w0
	mul	w0, w0, w0
	stp	x25, x26, [sp, 64]
	.cfi_offset 25, -128
	.cfi_offset 26, -120
	mov	x25, x2
	stp	x27, x28, [sp, 80]
	.cfi_offset 27, -112
	.cfi_offset 28, -104
	mov	x27, x3
	str	x1, [sp, 120]
	cbz	w0, .L13
	ubfiz	x2, x0, 2, 32
	mov	w1, 0
	mov	x0, x3
	bl	memset
.L13:
	cmp	w23, 0
	ble	.L9
	mov	w2, 0
	stp	x21, x22, [sp, 32]
	.cfi_offset 22, -152
	.cfi_offset 21, -160
	lsl	w21, w23, 1
	ptrue	p1.b, all
	lsl	w6, w23, 5
	sxtw	x22, w21
	sxtw	x28, w23
	sbfiz	x24, x23, 2, 32
	mov	w16, 0
	mov	w0, w2
	mov	w30, w21
.L12:
	mov	w10, w0
	add	w0, w0, 32
	cmp	w0, w23
	csel	w26, w0, w23, le
	cmp	w26, w10
	ble	.L31
	ldr	x1, [sp, 120]
	sxtw	x4, w16
	mov	w21, w16
	add	x15, x1, w16, sxtw 2
	mov	w13, w23
	mov	x2, 0
	stp	x19, x20, [sp, 16]
	.cfi_offset 20, -168
	.cfi_offset 19, -176
	mov	w17, w10
	mov	x16, x15
.L32:
	add	w5, w2, 32
	cmp	w5, w23
	str	w2, [sp, 132]
	csel	w5, w5, w23, le
	cmp	w5, w2
	ble	.L28
	sub	w1, w13, w23
	sub	w20, w5, #1
	stp	w0, w6, [sp, 144]
	sxtw	x10, w1
	add	w12, w2, 1
	str	x4, [sp, 152]
	lsl	x1, x2, 2
	mov	x15, x4
	mov	x18, 0
	mov	w11, w21
	mov	w14, w13
	str	x1, [sp, 136]
.L27:
	add	w8, w18, 32
	cmp	w8, w23
	csel	w8, w8, w23, le
	cmp	w8, w18
	ble	.L14
	mov	w21, w11
	stp	w11, w17, [sp, 160]
	sub	w8, w8, w18
	add	x0, x27, x15, lsl 2
	ldr	x11, [sp, 136]
	lsr	w1, w8, 2
	mov	x4, x16
	sub	w9, w8, #1
	lsl	x1, x1, 4
	str	x22, [sp, 96]
	and	w13, w8, -4
	and	w7, w8, 3
	stp	x15, x2, [sp, 168]
	mov	x6, x15
	mov	w3, w17
	str	x16, [sp, 184]
	.p2align 5,,15
.L15:
	cmp	w20, w12
	ble	.L51
	add	x17, x4, x11
	stp	x24, x28, [sp, 104]
	add	x19, x10, x18
	mov	w22, w14
	mov	w2, w12
	ldr	s1, [x17]
	cmp	w9, 2
	bls	.L52
.L45:
	sxtw	x28, w22
	dup	v4.4s, v1.s[0]
	add	x24, x25, x19, lsl 2
	mov	x15, 0
	ldr	s3, [x17, 4]
	add	x16, x28, x18
	add	x16, x25, x16, lsl 2
	dup	v3.4s, v3.s[0]
	.p2align 5,,15
.L25:
	ldr	q0, [x0, x15]
	ldr	q2, [x24, x15]
	ldr	q5, [x16, x15]
	fmla	v0.4s, v2.4s, v4.4s
	fmla	v0.4s, v3.4s, v5.4s
	str	q0, [x0, x15]
	add	x15, x15, 16
	cmp	x1, x15
	bne	.L25
	mov	w16, w13
	cbz	w7, .L18
.L16:
	uxtw	x15, w16
	add	x28, x28, x18
	mov	z1.s, s1
	ldr	x24, [sp, 120]
	sub	w16, w8, w16
	add	x28, x28, x15
	whilelo	p0.s, wzr, w16
	ld1w	z3.s, p0/z, [x25, x28, lsl 2]
	add	x16, x6, x15
	add	x15, x19, x15
	ld1w	z2.s, p0/z, [x25, x15, lsl 2]
	ld1w	z0.s, p0/z, [x27, x16, lsl 2]
	fmla	z0.s, p0/m, z2.s, z1.s
	add	w15, w21, w2
	add	x15, x24, w15, sxtw 2
	ld1rw	z2.s, p1/z, [x15]
	movprfx	z1, z0
	fmla	z1.s, p0/m, z2.s, z3.s
	st1w	z0.s, p0, [x27, x16, lsl 2]
	st1w	z1.s, p0, [x27, x16, lsl 2]
.L18:
	ldr	x16, [sp, 96]
	add	w15, w2, 2
	add	x17, x17, 8
	add	w22, w22, w30
	add	x19, x19, x16
	cmp	w20, w15
	ble	.L53
	ldr	s1, [x17]
	mov	w2, w15
	cmp	w9, 2
	bhi	.L45
.L52:
	mov	w16, 0
	sxtw	x28, w22
	b	.L16
.L53:
	ldp	x24, x28, [sp, 104]
	add	w2, w2, 1
.L30:
	sxtw	x15, w2
	mul	w2, w23, w2
	add	x2, x18, w2, sxtw
	.p2align 5,,15
.L24:
	ldr	s1, [x4, x15, lsl 2]
	cmp	w9, 2
	bls	.L35
.L23:
	dup	v2.4s, v1.s[0]
	add	x17, x25, x2, lsl 2
	mov	x16, 0
	.p2align 5,,15
.L21:
	ldr	q0, [x0, x16]
	ldr	q3, [x17, x16]
	fmla	v0.4s, v3.4s, v2.4s
	str	q0, [x0, x16]
	add	x16, x16, 16
	cmp	x1, x16
	bne	.L21
	cbz	w7, .L54
	mov	w16, w13
.L20:
	uxtw	x17, w16
	mov	z1.s, s1
	sub	w16, w8, w16
	whilelo	p0.s, wzr, w16
	add	x19, x6, x17
	add	x15, x15, 1
	ld1w	z0.s, p0/z, [x27, x19, lsl 2]
	add	x17, x17, x2
	ld1w	z2.s, p0/z, [x25, x17, lsl 2]
	fmla	z0.s, p0/m, z2.s, z1.s
	st1w	z0.s, p0, [x27, x19, lsl 2]
	add	x2, x2, x28
	cmp	w5, w15
	bgt	.L24
.L22:
	add	w3, w3, 1
	add	x6, x6, x28
	add	x0, x0, x24
	add	w21, w21, w23
	add	x4, x4, x24
	cmp	w26, w3
	bne	.L15
	ldr	x22, [sp, 96]
	ldp	x15, x2, [sp, 168]
	ldr	x16, [sp, 184]
	ldp	w11, w17, [sp, 160]
.L14:
	add	x18, x18, 32
	add	x15, x15, 32
	cmp	w23, w18
	bgt	.L27
	ldr	x4, [sp, 152]
	mov	w21, w11
	mov	w13, w14
	ldp	w0, w6, [sp, 144]
.L28:
	add	x2, x2, 32
	add	w13, w13, w6
	cmp	w23, w2
	bgt	.L32
	ldp	x19, x20, [sp, 16]
	.cfi_restore 20
	.cfi_restore 19
	mov	w16, w21
.L31:
	add	w16, w16, w6
	cmp	w0, w23
	blt	.L12
	ldp	x21, x22, [sp, 32]
	.cfi_restore 22
	.cfi_restore 21
.L9:
	ldp	x23, x24, [sp, 48]
	ldp	x25, x26, [sp, 64]
	ldp	x27, x28, [sp, 80]
	ldp	x29, x30, [sp], 192
	.cfi_restore 30
	.cfi_restore 29
	.cfi_restore 27
	.cfi_restore 28
	.cfi_restore 25
	.cfi_restore 26
	.cfi_restore 23
	.cfi_restore 24
	.cfi_def_cfa_offset 0
	ret
	.p2align 2,,3
.L54:
	.cfi_def_cfa_offset 192
	.cfi_offset 19, -176
	.cfi_offset 20, -168
	.cfi_offset 21, -160
	.cfi_offset 22, -152
	.cfi_offset 23, -144
	.cfi_offset 24, -136
	.cfi_offset 25, -128
	.cfi_offset 26, -120
	.cfi_offset 27, -112
	.cfi_offset 28, -104
	.cfi_offset 29, -192
	.cfi_offset 30, -184
	add	x15, x15, 1
	add	x2, x2, x28
	cmp	w5, w15
	ble	.L22
	ldr	s1, [x4, x15, lsl 2]
	b	.L23
	.p2align 2,,3
.L35:
	mov	w16, 0
	b	.L20
.L51:
	ldr	w2, [sp, 132]
	b	.L30
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
	bmi	.L55
	cmp	w2, 0
	ble	.L55
	sbfiz	x17, x2, 2, 32
	mov	x13, x6
	whilelo	p1.s, wzr, w3
	add	w16, w0, 1
	sxtw	x14, w14
	mov	w15, 0
	mov	w18, 0
	cntw	x4
.L57:
	mov	x8, 0
	mov	x0, 0
	cmp	w9, 0
	ble	.L64
	.p2align 5,,15
.L62:
	movi	v1.2s, #0
	mov	w7, w15
	mov	w6, 0
	mov	w5, 0
	.p2align 5,,15
.L65:
	cmp	w1, 0
	ble	.L61
	add	x2, x8, w7, sxtw
	add	x2, x11, x2, lsl 2
	mov	x0, 0
	add	x3, x12, w6, sxtw 2
	mov	p0.b, p1.b
	.p2align 5,,15
.L58:
	ld1w	z0.s, p0/z, [x2, x0, lsl 2]
	ld1w	z2.s, p0/z, [x3, x0, lsl 2]
	add	x0, x0, x4
	fmul	z0.s, p0/m, z0.s, z2.s
	fadda	s1, p0, s1, z0.s
	whilelo	p0.s, w0, w1
	b.any	.L58
.L61:
	add	w5, w5, 1
	add	w7, w7, w10
	add	w6, w6, w1
	cmp	w9, w5
	bne	.L65
	str	s1, [x13, x8, lsl 2]
	add	x0, x8, 1
	cmp	x14, x8
	beq	.L63
	mov	x8, x0
	b	.L62
.L64:
	cmp	x14, x0
	str	wzr, [x13, x0, lsl 2]
	add	x0, x0, 1
	bne	.L64
.L63:
	add	w18, w18, 1
	add	x13, x13, x17
	add	w15, w15, w10
	cmp	w18, w16
	bne	.L57
.L55:
	ret
	.cfi_endproc
.LFE2:
	.size	conv2d, .-conv2d
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
