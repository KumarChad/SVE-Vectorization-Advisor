	.text
	.file	"kernels.c"
	.globl	gemm_naive                      // -- Begin function gemm_naive
	.p2align	4
	.type	gemm_naive,@function
gemm_naive:                             // @gemm_naive
	.cfi_startproc
// %bb.0:
                                        // kill: def $w0 killed $w0 def $x0
	cmp	w0, #1
	b.lt	.LBB0_12
// %bb.1:
	index	z3.d, #0, #1
	mov	w14, #-2147483648               // =0x80000000
	mov	w11, w0
	movi	d5, #0000000000000000
	ptrue	p0.s, vl1
	cnth	x10
	rdvl	x13, #1
	mov	w8, wzr
	mov	x9, xzr
	ubfiz	x12, x0, #2, #32
	mov	z4.d, z3.d
	mov	z1.s, w14
	cntw	x14
	mov	z0.d, x11
	sel	z5.s, p0, z5.s, z1.s
	incd	z4.d
	mov	z2.d, x14
	ptrue	p0.s
	mov	w14, #2147483640                // =0x7ffffff8
	ptrue	p1.d
	b	.LBB0_3
	.p2align	5, , 16
.LBB0_2:                                //   in Loop: Header=BB0_3 Depth=1
	add	x9, x9, #1
	add	w8, w8, w0
	cmp	x9, x11
	b.eq	.LBB0_12
.LBB0_3:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB0_5 Depth 2
                                        //       Child Loop BB0_8 Depth 3
                                        //       Child Loop BB0_11 Depth 3
	add	x16, x1, w8, uxtw #2
	mul	x17, x9, x11
	mov	x15, xzr
	mov	x4, x2
	add	x17, x3, x17, lsl #2
	add	x18, x16, x13
	b	.LBB0_5
	.p2align	5, , 16
.LBB0_4:                                //   in Loop: Header=BB0_5 Depth=2
	str	s6, [x17, x15, lsl #2]
	add	x15, x15, #1
	add	x4, x4, #4
	cmp	x15, x11
	b.eq	.LBB0_2
.LBB0_5:                                //   Parent Loop BB0_3 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB0_8 Depth 3
                                        //       Child Loop BB0_11 Depth 3
	cmp	x10, x11
	b.ls	.LBB0_7
// %bb.6:                               //   in Loop: Header=BB0_5 Depth=2
	mov	x5, xzr
	movi	d6, #0000000000000000
	b	.LBB0_10
	.p2align	5, , 16
.LBB0_7:                                //   in Loop: Header=BB0_5 Depth=2
	lsr	x5, x13, #4
	mov	z16.d, z3.d
	mov	z17.d, z4.d
	mov	x6, xzr
	add	x7, x2, x15, lsl #2
	mul	x5, x5, x14
	mov	z6.d, z5.d
	mov	z7.d, z1.d
	and	x5, x5, x11
	.p2align	5, , 16
.LBB0_8:                                //   Parent Loop BB0_3 Depth=1
                                        //     Parent Loop BB0_5 Depth=2
                                        // =>    This Inner Loop Header: Depth=3
	add	z18.d, z16.d, z2.d
	add	z19.d, z17.d, z2.d
	ld1w	{ z20.s }, p0/z, [x16, x6, lsl #2]
	ld1w	{ z21.s }, p0/z, [x18, x6, lsl #2]
	movprfx	z22, z19
	mul	z22.d, p1/m, z22.d, z0.d
	movprfx	z23, z18
	mul	z23.d, p1/m, z23.d, z0.d
	add	x6, x6, x10
	cmp	x5, x6
	mul	z17.d, p1/m, z17.d, z0.d
	mul	z16.d, p1/m, z16.d, z0.d
	ld1w	{ z16.d }, p1/z, [x7, z16.d, lsl #2]
	ld1w	{ z17.d }, p1/z, [x7, z17.d, lsl #2]
	uzp1	z16.s, z16.s, z17.s
	ld1w	{ z17.d }, p1/z, [x7, z23.d, lsl #2]
	ld1w	{ z22.d }, p1/z, [x7, z22.d, lsl #2]
	fmla	z6.s, p0/m, z20.s, z16.s
	add	z16.d, z18.d, z2.d
	uzp1	z17.s, z17.s, z22.s
	fmla	z7.s, p0/m, z21.s, z17.s
	add	z17.d, z19.d, z2.d
	b.ne	.LBB0_8
// %bb.9:                               //   in Loop: Header=BB0_5 Depth=2
	fadd	z6.s, z7.s, z6.s
	cmp	x5, x11
	faddv	s6, p0, z6.s
	b.eq	.LBB0_4
.LBB0_10:                               //   in Loop: Header=BB0_5 Depth=2
	madd	x7, x12, x5, x4
	add	x6, x16, x5, lsl #2
	sub	x5, x11, x5
	.p2align	5, , 16
.LBB0_11:                               //   Parent Loop BB0_3 Depth=1
                                        //     Parent Loop BB0_5 Depth=2
                                        // =>    This Inner Loop Header: Depth=3
	ldr	s7, [x6], #4
	ldr	s16, [x7]
	add	x7, x7, x12
	subs	x5, x5, #1
	fmadd	s6, s7, s16, s6
	b.ne	.LBB0_11
	b	.LBB0_4
.LBB0_12:
	ret
.Lfunc_end0:
	.size	gemm_naive, .Lfunc_end0-gemm_naive
	.cfi_endproc
                                        // -- End function
	.globl	gemm_tiled                      // -- Begin function gemm_tiled
	.p2align	4
	.type	gemm_tiled,@function
gemm_tiled:                             // @gemm_tiled
	.cfi_startproc
// %bb.0:
	cbz	w0, .LBB1_19
// %bb.1:
	sub	sp, sp, #160
	.cfi_def_cfa_offset 160
	stp	x29, x30, [sp, #64]             // 16-byte Folded Spill
	stp	x28, x27, [sp, #80]             // 16-byte Folded Spill
	stp	x26, x25, [sp, #96]             // 16-byte Folded Spill
	stp	x24, x23, [sp, #112]            // 16-byte Folded Spill
	stp	x22, x21, [sp, #128]            // 16-byte Folded Spill
	stp	x20, x19, [sp, #144]            // 16-byte Folded Spill
	add	x29, sp, #64
	.cfi_def_cfa w29, 96
	.cfi_offset w19, -8
	.cfi_offset w20, -16
	.cfi_offset w21, -24
	.cfi_offset w22, -32
	.cfi_offset w23, -40
	.cfi_offset w24, -48
	.cfi_offset w25, -56
	.cfi_offset w26, -64
	.cfi_offset w27, -72
	.cfi_offset w28, -80
	.cfi_offset w30, -88
	.cfi_offset w29, -96
	mul	w8, w0, w0
	mov	x20, x2
	mov	x21, x1
	mov	w22, w0
	mov	x0, x3
	mov	w1, wzr
	mov	x19, x3
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	ubfiz	x2, x8, #2, #32
	bl	memset
	cmp	w22, #1
	b.lt	.LBB1_18
// %bb.2:
	mov	w8, w22
	cnth	x11
	mov	x25, xzr
	stur	wzr, [x29, #-20]                // 4-byte Folded Spill
	str	x8, [sp, #24]                   // 8-byte Folded Spill
	lsl	w8, w22, #5
	ptrue	p0.s
	str	w8, [sp, #20]                   // 4-byte Folded Spill
	rdvl	x8, #1
	add	x9, x20, x8
	add	x8, x19, x8
	stp	x8, x9, [sp]                    // 16-byte Folded Spill
	b	.LBB1_4
	.p2align	5, , 16
.LBB1_3:                                //   in Loop: Header=BB1_4 Depth=1
	ldur	w8, [x29, #-20]                 // 4-byte Folded Reload
	ldr	w9, [sp, #20]                   // 4-byte Folded Reload
	add	x25, x25, #32
	cmp	w25, w22
	add	w8, w8, w9
	stur	w8, [x29, #-20]                 // 4-byte Folded Spill
	b.ge	.LBB1_18
.LBB1_4:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB1_6 Depth 2
                                        //       Child Loop BB1_8 Depth 3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	add	w8, w25, #32
	mov	w15, wzr
	mov	x14, xzr
	str	x25, [sp, #32]                  // 8-byte Folded Spill
	cmp	w8, w22
	csel	w8, w8, w22, lt
	sxtw	x17, w8
	b	.LBB1_6
	.p2align	5, , 16
.LBB1_5:                                //   in Loop: Header=BB1_6 Depth=2
	ldr	w8, [sp, #20]                   // 4-byte Folded Reload
	add	x14, x14, #32
	cmp	w14, w22
	add	w15, w15, w8
	b.ge	.LBB1_3
.LBB1_6:                                //   Parent Loop BB1_4 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB1_8 Depth 3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	add	w8, w14, #32
	ldp	x1, x3, [sp]                    // 16-byte Folded Reload
	mov	x10, xzr
	mov	x6, xzr
	mov	x2, x19
	mov	x4, x20
	cmp	w8, w22
	csel	w8, w8, w22, lt
	sxtw	x0, w8
	b	.LBB1_8
	.p2align	5, , 16
.LBB1_7:                                //   in Loop: Header=BB1_8 Depth=3
	ldp	x6, x10, [x29, #-16]            // 16-byte Folded Reload
	ldr	x25, [sp, #32]                  // 8-byte Folded Reload
	add	x4, x4, #128
	add	x3, x3, #128
	add	x2, x2, #128
	add	x1, x1, #128
	add	x10, x10, #1
	cmp	w6, w22
	b.ge	.LBB1_5
.LBB1_8:                                //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        // =>    This Loop Header: Depth=3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ldr	x8, [sp, #24]                   // 8-byte Folded Reload
	add	x12, x6, #32
	orr	x9, x6, #0x1
	ldur	w24, [x29, #-20]                // 4-byte Folded Reload
	stp	x12, x10, [x29, #-16]           // 16-byte Folded Spill
	cmp	x12, x8
	csel	x8, x12, x8, lt
	cmp	x8, x9
	csel	x8, x8, x9, gt
	cmp	w12, w22
	sub	x7, x8, x10, lsl #5
	csel	w8, w12, w22, lt
	sxtw	x23, w8
	b	.LBB1_10
	.p2align	5, , 16
.LBB1_9:                                //   in Loop: Header=BB1_10 Depth=4
	add	x25, x25, #1
	add	w24, w24, w22
	cmp	x25, x17
	b.ge	.LBB1_7
.LBB1_10:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        // =>      This Loop Header: Depth=4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ubfiz	x8, x24, #2, #32
	mov	w13, w15
	mov	x16, x14
	add	x26, x19, x8
	add	x27, x2, x8
	add	x28, x1, x8
	mul	w8, w25, w22
	add	x30, x21, w8, uxtw #2
	b	.LBB1_12
	.p2align	5, , 16
.LBB1_11:                               //   in Loop: Header=BB1_12 Depth=5
	add	x16, x16, #1
	add	w13, w13, w22
	cmp	x16, x0
	b.ge	.LBB1_9
.LBB1_12:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        // =>        This Loop Header: Depth=5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ldr	s0, [x30, x16, lsl #2]
	ubfiz	x8, x13, #2, #32
	cmp	x7, x11
	mov	x5, x6
	b.lo	.LBB1_16
// %bb.13:                              //   in Loop: Header=BB1_12 Depth=5
	neg	x12, x11
	mov	z1.s, s0
	mov	x9, xzr
	add	x10, x4, x8
	add	x18, x3, x8
	and	x12, x7, x12
	add	x5, x6, x12
	.p2align	5, , 16
.LBB1_14:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        //           Parent Loop BB1_12 Depth=5
                                        // =>          This Inner Loop Header: Depth=6
	ld1w	{ z2.s }, p0/z, [x10, x9, lsl #2]
	ld1w	{ z3.s }, p0/z, [x18, x9, lsl #2]
	ld1w	{ z4.s }, p0/z, [x27, x9, lsl #2]
	fmad	z2.s, p0/m, z1.s, z4.s
	ld1w	{ z5.s }, p0/z, [x28, x9, lsl #2]
	fmad	z3.s, p0/m, z1.s, z5.s
	st1w	{ z2.s }, p0, [x27, x9, lsl #2]
	st1w	{ z3.s }, p0, [x28, x9, lsl #2]
	add	x9, x9, x11
	cmp	x12, x9
	b.ne	.LBB1_14
// %bb.15:                              //   in Loop: Header=BB1_12 Depth=5
	cmp	x7, x12
	b.eq	.LBB1_11
.LBB1_16:                               //   in Loop: Header=BB1_12 Depth=5
	add	x8, x20, x8
	.p2align	5, , 16
.LBB1_17:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        //           Parent Loop BB1_12 Depth=5
                                        // =>          This Inner Loop Header: Depth=6
	ldr	s1, [x8, x5, lsl #2]
	ldr	s2, [x26, x5, lsl #2]
	fmadd	s1, s0, s1, s2
	str	s1, [x26, x5, lsl #2]
	add	x5, x5, #1
	cmp	x5, x23
	b.lt	.LBB1_17
	b	.LBB1_11
.LBB1_18:
	.cfi_def_cfa wsp, 160
	ldp	x20, x19, [sp, #144]            // 16-byte Folded Reload
	ldp	x22, x21, [sp, #128]            // 16-byte Folded Reload
	ldp	x24, x23, [sp, #112]            // 16-byte Folded Reload
	ldp	x26, x25, [sp, #96]             // 16-byte Folded Reload
	ldp	x28, x27, [sp, #80]             // 16-byte Folded Reload
	ldp	x29, x30, [sp, #64]             // 16-byte Folded Reload
	add	sp, sp, #160
	.cfi_def_cfa_offset 0
	.cfi_restore w19
	.cfi_restore w20
	.cfi_restore w21
	.cfi_restore w22
	.cfi_restore w23
	.cfi_restore w24
	.cfi_restore w25
	.cfi_restore w26
	.cfi_restore w27
	.cfi_restore w28
	.cfi_restore w30
	.cfi_restore w29
.LBB1_19:
	ret
.Lfunc_end1:
	.size	gemm_tiled, .Lfunc_end1-gemm_tiled
	.cfi_endproc
                                        // -- End function
	.globl	conv2d                          // -- Begin function conv2d
	.p2align	4
	.type	conv2d,@function
conv2d:                                 // @conv2d
	.cfi_startproc
// %bb.0:
	stp	x29, x30, [sp, #-96]!           // 16-byte Folded Spill
	.cfi_def_cfa_offset 96
	stp	x28, x27, [sp, #16]             // 16-byte Folded Spill
	stp	x26, x25, [sp, #32]             // 16-byte Folded Spill
	stp	x24, x23, [sp, #48]             // 16-byte Folded Spill
	stp	x22, x21, [sp, #64]             // 16-byte Folded Spill
	stp	x20, x19, [sp, #80]             // 16-byte Folded Spill
	mov	x29, sp
	.cfi_def_cfa w29, 96
	.cfi_offset w19, -8
	.cfi_offset w20, -16
	.cfi_offset w21, -24
	.cfi_offset w22, -32
	.cfi_offset w23, -40
	.cfi_offset w24, -48
	.cfi_offset w25, -56
	.cfi_offset w26, -64
	.cfi_offset w27, -72
	.cfi_offset w28, -80
	.cfi_offset w30, -88
	.cfi_offset w29, -96
	.cfi_remember_state
	subs	w12, w0, w2
                                        // kill: def $w3 killed $w3 def $x3
	b.lt	.LBB2_37
// %bb.1:
	sub	w8, w1, w3
	tbnz	w8, #31, .LBB2_37
// %bb.2:
	mov	x19, x6
	add	w21, w8, #1
	cmp	w2, #0
	b.le	.LBB2_23
// %bb.3:
	cmp	w3, #0
	b.le	.LBB2_25
// %bb.4:
	mov	w17, #-2147483648               // =0x80000000
	mov	w11, w3
	cnth	x10
	mov	x8, xzr
	mov	x9, xzr
	rdvl	x16, #1
	add	w12, w12, #1
	mov	w13, w2
	mov	w15, w1
	ptrue	p0.s, vl1
	mov	w0, #2147483640                 // =0x7ffffff8
	sub	x14, x11, #1
	lsr	x18, x14, #32
	mov	z0.s, w17
	ubfiz	x17, x3, #2, #32
	ptrue	p1.s
	b	.LBB2_6
	.p2align	5, , 16
.LBB2_5:                                //   in Loop: Header=BB2_6 Depth=1
	add	x9, x9, #1
	add	x8, x8, x15
	cmp	x9, x12
	b.eq	.LBB2_37
.LBB2_6:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB2_8 Depth 2
                                        //       Child Loop BB2_10 Depth 3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	mul	w3, w21, w9
	mul	x2, x9, x15
	mov	x1, xzr
	mov	x6, x8
	add	x3, x19, w3, uxtw #2
	b	.LBB2_8
	.p2align	5, , 16
.LBB2_7:                                //   in Loop: Header=BB2_8 Depth=2
	str	s1, [x3, x1, lsl #2]
	add	x1, x1, #1
	add	x6, x6, #1
	cmp	x1, x21
	b.eq	.LBB2_5
.LBB2_8:                                //   Parent Loop BB2_6 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB2_10 Depth 3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	movi	d1, #0000000000000000
	mov	x7, xzr
	add	x20, x2, x1
	mov	x22, x6
	mov	x23, x5
	b	.LBB2_10
	.p2align	5, , 16
.LBB2_9:                                //   in Loop: Header=BB2_10 Depth=3
	add	x7, x7, #1
	add	x23, x23, x17
	add	x22, x22, x15
	cmp	x7, x13
	b.eq	.LBB2_7
.LBB2_10:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        // =>    This Loop Header: Depth=3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	cmp	x10, x11
	b.hi	.LBB2_12
// %bb.11:                              //   in Loop: Header=BB2_10 Depth=3
	madd	w24, w7, w15, w20
	add	w25, w24, w14
	cmp	w25, w24
	ccmp	x18, #0, #0, ge
	b.eq	.LBB2_20
.LBB2_12:                               //   in Loop: Header=BB2_10 Depth=3
	mov	x24, xzr
.LBB2_13:                               //   in Loop: Header=BB2_10 Depth=3
	sub	w25, w11, w24
	ands	x26, x25, #0x3
	b.eq	.LBB2_17
// %bb.14:                              //   in Loop: Header=BB2_10 Depth=3
	mov	x25, x24
	.p2align	5, , 16
.LBB2_15:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	w27, w22, w25
	ldr	s3, [x23, x25, lsl #2]
	add	x25, x25, #1
	subs	x26, x26, #1
	ldr	s2, [x4, w27, sxtw #2]
	fmadd	s1, s2, s3, s1
	b.ne	.LBB2_15
// %bb.16:                              //   in Loop: Header=BB2_10 Depth=3
	sub	x24, x24, x11
	cmn	x24, #4
	b.hi	.LBB2_9
	b	.LBB2_18
	.p2align	5, , 16
.LBB2_17:                               //   in Loop: Header=BB2_10 Depth=3
	mov	x25, x24
	sub	x24, x24, x11
	cmn	x24, #4
	b.hi	.LBB2_9
.LBB2_18:                               //   in Loop: Header=BB2_10 Depth=3
	add	x24, x23, x25, lsl #2
	.p2align	5, , 16
.LBB2_19:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	w26, w22, w25
	ldp	s3, s4, [x24]
	add	x25, x25, #4
	ldr	s2, [x4, w26, sxtw #2]
	add	w27, w26, #1
	cmp	x11, x25
	fmadd	s1, s2, s3, s1
	ldr	s2, [x4, w27, sxtw #2]
	add	w27, w26, #2
	add	w26, w26, #3
	fmadd	s1, s2, s4, s1
	ldr	s2, [x4, w27, sxtw #2]
	ldp	s3, s4, [x24, #8]
	add	x24, x24, #16
	fmadd	s1, s2, s3, s1
	ldr	s2, [x4, w26, sxtw #2]
	fmadd	s1, s2, s4, s1
	b.ne	.LBB2_19
	b	.LBB2_9
	.p2align	5, , 16
.LBB2_20:                               //   in Loop: Header=BB2_10 Depth=3
	lsr	x24, x16, #4
	sel	z1.s, p0, z1.s, z0.s
	mov	z2.d, z0.d
	mov	x25, xzr
	add	x26, x23, x16
	mul	x24, x24, x0
	and	x24, x24, x11
	.p2align	5, , 16
.LBB2_21:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	w27, w22, w25
	ld1w	{ z5.s }, p1/z, [x23, x25, lsl #2]
	ld1w	{ z6.s }, p1/z, [x26, x25, lsl #2]
	add	x25, x25, x10
	sxtw	x28, w27
	add	x27, x4, w27, sxtw #2
	cmp	x24, x25
	ld1w	{ z3.s }, p1/z, [x4, x28, lsl #2]
	ld1w	{ z4.s }, p1/z, [x27, #1, mul vl]
	fmla	z1.s, p1/m, z3.s, z5.s
	fmla	z2.s, p1/m, z4.s, z6.s
	b.ne	.LBB2_21
// %bb.22:                              //   in Loop: Header=BB2_10 Depth=3
	fadd	z1.s, z2.s, z1.s
	cmp	x24, x11
	faddv	s1, p1, z1.s
	b.eq	.LBB2_9
	b	.LBB2_13
.LBB2_23:
	add	w22, w12, #1
	ubfiz	x20, x21, #2, #32
	cmp	w22, #1
	b.ne	.LBB2_34
// %bb.24:
	mov	w8, wzr
	tbz	w22, #0, .LBB2_37
	b	.LBB2_38
.LBB2_25:
	add	w10, w12, #1
	rdvl	x12, #1
	mov	w14, #-8                        // =0xfffffff8
	mov	z0.s, #0                        // =0x0
	mov	w8, wzr
	mov	x9, xzr
	cnth	x11
	lsr	x13, x12, #4
	ptrue	p0.s
	mul	x13, x13, x14
	b	.LBB2_27
	.p2align	5, , 16
.LBB2_26:                               //   in Loop: Header=BB2_27 Depth=1
	add	x9, x9, #1
	add	w8, w8, w21
	cmp	x9, x10
	b.eq	.LBB2_37
.LBB2_27:                               // =>This Loop Header: Depth=1
                                        //     Child Loop BB2_30 Depth 2
                                        //     Child Loop BB2_33 Depth 2
	ubfiz	x14, x8, #2, #32
	cmp	x11, x21
	b.ls	.LBB2_29
// %bb.28:                              //   in Loop: Header=BB2_27 Depth=1
	mov	x15, xzr
	b	.LBB2_32
	.p2align	5, , 16
.LBB2_29:                               //   in Loop: Header=BB2_27 Depth=1
	add	x17, x19, x14
	mov	x16, xzr
	and	x15, x13, x21
	add	x18, x17, x12
	.p2align	5, , 16
.LBB2_30:                               //   Parent Loop BB2_27 Depth=1
                                        // =>  This Inner Loop Header: Depth=2
	st1w	{ z0.s }, p0, [x17, x16, lsl #2]
	st1w	{ z0.s }, p0, [x18, x16, lsl #2]
	add	x16, x16, x11
	cmp	x15, x16
	b.ne	.LBB2_30
// %bb.31:                              //   in Loop: Header=BB2_27 Depth=1
	cmp	x15, x21
	b.eq	.LBB2_26
.LBB2_32:                               //   in Loop: Header=BB2_27 Depth=1
	add	x14, x14, x15, lsl #2
	sub	x15, x21, x15
	add	x14, x19, x14
	.p2align	5, , 16
.LBB2_33:                               //   Parent Loop BB2_27 Depth=1
                                        // =>  This Inner Loop Header: Depth=2
	str	wzr, [x14], #4
	subs	x15, x15, #1
	b.ne	.LBB2_33
	b	.LBB2_26
.LBB2_34:
	and	x8, x22, #0xfffffffe
	mov	x23, xzr
	mov	w24, wzr
	lsl	w25, w21, #1
	neg	x26, x8
	.p2align	5, , 16
.LBB2_35:                               // =>This Inner Loop Header: Depth=1
	add	x0, x19, w24, uxtw #2
	mov	w1, wzr
	mov	x2, x20
	bl	memset
	add	w8, w21, w24
	mov	w1, wzr
	mov	x2, x20
	add	x0, x19, w8, uxtw #2
	bl	memset
	sub	x23, x23, #2
	add	w24, w24, w25
	cmp	x26, x23
	b.ne	.LBB2_35
// %bb.36:
	neg	w8, w23
	tbnz	w22, #0, .LBB2_38
.LBB2_37:
	.cfi_def_cfa wsp, 96
	ldp	x20, x19, [sp, #80]             // 16-byte Folded Reload
	ldp	x22, x21, [sp, #64]             // 16-byte Folded Reload
	ldp	x24, x23, [sp, #48]             // 16-byte Folded Reload
	ldp	x26, x25, [sp, #32]             // 16-byte Folded Reload
	ldp	x28, x27, [sp, #16]             // 16-byte Folded Reload
	ldp	x29, x30, [sp], #96             // 16-byte Folded Reload
	.cfi_def_cfa_offset 0
	.cfi_restore w19
	.cfi_restore w20
	.cfi_restore w21
	.cfi_restore w22
	.cfi_restore w23
	.cfi_restore w24
	.cfi_restore w25
	.cfi_restore w26
	.cfi_restore w27
	.cfi_restore w28
	.cfi_restore w30
	.cfi_restore w29
	ret
.LBB2_38:
	.cfi_restore_state
	mul	w8, w21, w8
	mov	w1, wzr
	add	x0, x19, w8, uxtw #2
	mov	x2, x20
	.cfi_def_cfa wsp, 96
	ldp	x20, x19, [sp, #80]             // 16-byte Folded Reload
	ldp	x22, x21, [sp, #64]             // 16-byte Folded Reload
	ldp	x24, x23, [sp, #48]             // 16-byte Folded Reload
	ldp	x26, x25, [sp, #32]             // 16-byte Folded Reload
	ldp	x28, x27, [sp, #16]             // 16-byte Folded Reload
	ldp	x29, x30, [sp], #96             // 16-byte Folded Reload
	.cfi_def_cfa_offset 0
	.cfi_restore w19
	.cfi_restore w20
	.cfi_restore w21
	.cfi_restore w22
	.cfi_restore w23
	.cfi_restore w24
	.cfi_restore w25
	.cfi_restore w26
	.cfi_restore w27
	.cfi_restore w28
	.cfi_restore w30
	.cfi_restore w29
	b	memset
.Lfunc_end2:
	.size	conv2d, .Lfunc_end2-conv2d
	.cfi_endproc
                                        // -- End function
	.ident	"Ubuntu clang version 18.1.3 (1ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
