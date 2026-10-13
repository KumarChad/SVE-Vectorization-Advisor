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
	b.lt	.LBB0_18
// %bb.1:
	str	x25, [sp, #-64]!                // 8-byte Folded Spill
	.cfi_def_cfa_offset 64
	stp	x24, x23, [sp, #16]             // 16-byte Folded Spill
	stp	x22, x21, [sp, #32]             // 16-byte Folded Spill
	stp	x20, x19, [sp, #48]             // 16-byte Folded Spill
	.cfi_offset w19, -8
	.cfi_offset w20, -16
	.cfi_offset w21, -24
	.cfi_offset w22, -32
	.cfi_offset w23, -40
	.cfi_offset w24, -48
	.cfi_offset w25, -64
	mov	w10, w0
	and	x11, x10, #0x7ffffffe
	ubfiz	x12, x0, #3, #32
	add	x13, x1, #4
	ubfiz	x14, x0, #2, #32
	ubfiz	x15, x0, #4, #32
	add	x16, x1, #8
	mov	w8, wzr
	mov	x9, xzr
	b	.LBB0_3
	.p2align	5, , 16
.LBB0_2:                                //   in Loop: Header=BB0_3 Depth=1
	add	x9, x9, #1
	add	w8, w8, w0
	cmp	x9, x10
	b.eq	.LBB0_17
.LBB0_3:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB0_5 Depth 2
                                        //       Child Loop BB0_8 Depth 3
                                        //       Child Loop BB0_12 Depth 3
                                        //       Child Loop BB0_16 Depth 3
	mul	x5, x9, x10
	ubfiz	x6, x8, #2, #32
	mov	x17, xzr
	mov	x7, x2
	add	x18, x1, x6
	add	x4, x13, x6
	add	x6, x16, x6
	add	x5, x3, x5, lsl #2
	b	.LBB0_5
	.p2align	5, , 16
.LBB0_4:                                //   in Loop: Header=BB0_5 Depth=2
	str	s0, [x5, x17, lsl #2]
	add	x17, x17, #1
	add	x7, x7, #4
	cmp	x17, x10
	b.eq	.LBB0_2
.LBB0_5:                                //   Parent Loop BB0_3 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB0_8 Depth 3
                                        //       Child Loop BB0_12 Depth 3
                                        //       Child Loop BB0_16 Depth 3
	cmp	w0, #1
	b.ne	.LBB0_7
// %bb.6:                               //   in Loop: Header=BB0_5 Depth=2
	mov	x19, xzr
	movi	d0, #0000000000000000
	b	.LBB0_10
	.p2align	5, , 16
.LBB0_7:                                //   in Loop: Header=BB0_5 Depth=2
	movi	d0, #0000000000000000
	movi	v1.2s, #128, lsl #24
	mov	x19, x4
	mov	x20, x7
	mov	x21, x11
	.p2align	5, , 16
.LBB0_8:                                //   Parent Loop BB0_3 Depth=1
                                        //     Parent Loop BB0_5 Depth=2
                                        // =>    This Inner Loop Header: Depth=3
	ldp	s2, s3, [x19, #-4]
	ldr	s4, [x20]
	ldr	s5, [x20, x10, lsl #2]
	subs	x21, x21, #2
	add	x20, x20, x12
	add	x19, x19, #8
	fmadd	s0, s2, s4, s0
	fmadd	s1, s3, s5, s1
	b.ne	.LBB0_8
// %bb.9:                               //   in Loop: Header=BB0_5 Depth=2
	fadd	s0, s1, s0
	cmp	x11, x10
	mov	x19, x11
	b.eq	.LBB0_4
.LBB0_10:                               //   in Loop: Header=BB0_5 Depth=2
	sub	w20, w10, w19
	ands	x21, x20, #0x3
	b.eq	.LBB0_14
// %bb.11:                              //   in Loop: Header=BB0_5 Depth=2
	mul	x22, x14, x19
	mov	x20, x19
	.p2align	5, , 16
.LBB0_12:                               //   Parent Loop BB0_3 Depth=1
                                        //     Parent Loop BB0_5 Depth=2
                                        // =>    This Inner Loop Header: Depth=3
	ldr	s1, [x18, x20, lsl #2]
	ldr	s2, [x7, x22]
	add	x20, x20, #1
	add	x22, x22, x14
	subs	x21, x21, #1
	fmadd	s0, s1, s2, s0
	b.ne	.LBB0_12
// %bb.13:                              //   in Loop: Header=BB0_5 Depth=2
	sub	x19, x19, x10
	cmn	x19, #4
	b.hi	.LBB0_4
	b	.LBB0_15
	.p2align	5, , 16
.LBB0_14:                               //   in Loop: Header=BB0_5 Depth=2
	mov	x20, x19
	sub	x19, x19, x10
	cmn	x19, #4
	b.hi	.LBB0_4
.LBB0_15:                               //   in Loop: Header=BB0_5 Depth=2
	add	x21, x20, #3
	add	x23, x20, #2
	madd	x22, x14, x20, x14
	mul	x24, x14, x20
	sub	x19, x10, x20
	add	x20, x6, x20, lsl #2
	mov	x25, x7
	mul	x21, x14, x21
	mul	x23, x14, x23
	.p2align	5, , 16
.LBB0_16:                               //   Parent Loop BB0_3 Depth=1
                                        //     Parent Loop BB0_5 Depth=2
                                        // =>    This Inner Loop Header: Depth=3
	ldr	s1, [x25, x24]
	ldp	s2, s3, [x20, #-8]
	subs	x19, x19, #4
	fmadd	s0, s2, s1, s0
	ldr	s1, [x25, x22]
	fmadd	s0, s3, s1, s0
	ldr	s1, [x25, x23]
	ldp	s2, s3, [x20], #16
	fmadd	s0, s2, s1, s0
	ldr	s1, [x25, x21]
	add	x25, x25, x15
	fmadd	s0, s3, s1, s0
	b.ne	.LBB0_16
	b	.LBB0_4
.LBB0_17:
	ldp	x20, x19, [sp, #48]             // 16-byte Folded Reload
	ldp	x22, x21, [sp, #32]             // 16-byte Folded Reload
	ldp	x24, x23, [sp, #16]             // 16-byte Folded Reload
	ldr	x25, [sp], #64                  // 8-byte Folded Reload
	.cfi_def_cfa_offset 0
	.cfi_restore w19
	.cfi_restore w20
	.cfi_restore w21
	.cfi_restore w22
	.cfi_restore w23
	.cfi_restore w24
	.cfi_restore w25
.LBB0_18:
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
	sub	sp, sp, #144
	.cfi_def_cfa_offset 144
	stp	x29, x30, [sp, #48]             // 16-byte Folded Spill
	stp	x28, x27, [sp, #64]             // 16-byte Folded Spill
	stp	x26, x25, [sp, #80]             // 16-byte Folded Spill
	stp	x24, x23, [sp, #96]             // 16-byte Folded Spill
	stp	x22, x21, [sp, #112]            // 16-byte Folded Spill
	stp	x20, x19, [sp, #128]            // 16-byte Folded Spill
	add	x29, sp, #48
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
	mov	x19, x3
	mov	x21, x1
	mov	w22, w0
	mov	x0, x3
	mov	w1, wzr
	cmp	w8, #1
	csinc	w8, w8, wzr, hi
	ubfiz	x2, x8, #2, #32
	bl	memset
	cmp	w22, #1
	b.lt	.LBB1_18
// %bb.2:
	mov	w8, w22
	str	x8, [sp, #16]                   // 8-byte Folded Spill
	lsl	w8, w22, #5
	stur	wzr, [x29, #-12]                // 4-byte Folded Spill
	mov	x26, xzr
	str	w8, [sp, #12]                   // 4-byte Folded Spill
	add	x8, x20, #16
	str	x8, [sp]                        // 8-byte Folded Spill
	b	.LBB1_4
	.p2align	5, , 16
.LBB1_3:                                //   in Loop: Header=BB1_4 Depth=1
	ldur	w8, [x29, #-12]                 // 4-byte Folded Reload
	ldr	w9, [sp, #12]                   // 4-byte Folded Reload
	add	x26, x26, #32
	cmp	w26, w22
	add	w8, w8, w9
	stur	w8, [x29, #-12]                 // 4-byte Folded Spill
	b.ge	.LBB1_18
.LBB1_4:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB1_6 Depth 2
                                        //       Child Loop BB1_8 Depth 3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	add	w8, w26, #32
	mov	w13, wzr
	mov	x11, xzr
	str	x26, [sp, #24]                  // 8-byte Folded Spill
	cmp	w8, w22
	csel	w8, w8, w22, lt
	sxtw	x15, w8
	b	.LBB1_6
	.p2align	5, , 16
.LBB1_5:                                //   in Loop: Header=BB1_6 Depth=2
	ldr	w8, [sp, #12]                   // 4-byte Folded Reload
	add	x11, x11, #32
	cmp	w11, w22
	add	w13, w13, w8
	b.ge	.LBB1_3
.LBB1_6:                                //   Parent Loop BB1_4 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB1_8 Depth 3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	add	w8, w11, #32
	ldr	x18, [sp]                       // 8-byte Folded Reload
	mov	w1, #1                          // =0x1
	mov	w2, #32                         // =0x20
	mov	x10, xzr
	mov	x3, xzr
	mov	x0, x19
	cmp	w8, w22
	csel	w8, w8, w22, lt
	sxtw	x17, w8
	b	.LBB1_8
	.p2align	5, , 16
.LBB1_7:                                //   in Loop: Header=BB1_8 Depth=3
	ldur	x10, [x29, #-8]                 // 8-byte Folded Reload
	ldr	x26, [sp, #24]                  // 8-byte Folded Reload
	add	x2, x2, #32
	add	x1, x1, #32
	add	x0, x0, #128
	add	x18, x18, #128
	cmp	w4, w22
	mov	x3, x4
	add	x10, x10, #1
	b.ge	.LBB1_5
.LBB1_8:                                //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        // =>    This Loop Header: Depth=3
                                        //         Child Loop BB1_10 Depth 4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ldr	x9, [sp, #16]                   // 8-byte Folded Reload
	add	x4, x3, #32
	ldur	w25, [x29, #-12]                // 4-byte Folded Reload
	stur	x10, [x29, #-8]                 // 8-byte Folded Spill
	cmp	x2, x9
	csel	x8, x2, x9, lt
	cmp	x8, x1
	csel	x8, x8, x1, gt
	cmp	x4, x9
	and	x16, x8, #0xfffffffffffffff8
	csel	x8, x4, x9, lt
	orr	x9, x3, #0x1
	cmp	x8, x9
	csel	x8, x8, x9, gt
	cmp	w4, w22
	sub	x6, x8, x10, lsl #5
	and	x23, x8, #0x7
	csel	w9, w4, w22, lt
	sxtw	x7, w9
	sub	x8, x6, x23
	add	x24, x3, x8
	b	.LBB1_10
	.p2align	5, , 16
.LBB1_9:                                //   in Loop: Header=BB1_10 Depth=4
	add	x26, x26, #1
	add	w25, w25, w22
	cmp	x26, x15
	b.ge	.LBB1_7
.LBB1_10:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        // =>      This Loop Header: Depth=4
                                        //           Child Loop BB1_12 Depth 5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ubfiz	x8, x25, #2, #32
	mov	w12, w13
	mov	x14, x11
	add	x27, x19, x8
	add	x10, x0, x8
	mul	w8, w26, w22
	add	x30, x21, w8, uxtw #2
	b	.LBB1_12
	.p2align	5, , 16
.LBB1_11:                               //   in Loop: Header=BB1_12 Depth=5
	add	x14, x14, #1
	add	w12, w12, w22
	cmp	x14, x17
	b.ge	.LBB1_9
.LBB1_12:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        // =>        This Loop Header: Depth=5
                                        //             Child Loop BB1_14 Depth 6
                                        //             Child Loop BB1_17 Depth 6
	ldr	s0, [x30, x14, lsl #2]
	ubfiz	x8, x12, #2, #32
	cmp	x6, #8
	mov	x9, x3
	b.lo	.LBB1_16
// %bb.13:                              //   in Loop: Header=BB1_12 Depth=5
	dup	v1.4s, v0.s[0]
	add	x9, x18, x8
	mov	x28, x10
	mov	x5, x16
	.p2align	5, , 16
.LBB1_14:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        //           Parent Loop BB1_12 Depth=5
                                        // =>          This Inner Loop Header: Depth=6
	ldp	q2, q3, [x9, #-16]
	ldp	q4, q5, [x28]
	sub	x5, x5, #8
	add	x9, x9, #32
	cmp	x3, x5
	fmla	v5.4s, v3.4s, v1.4s
	fmla	v4.4s, v2.4s, v1.4s
	stp	q4, q5, [x28], #32
	b.ne	.LBB1_14
// %bb.15:                              //   in Loop: Header=BB1_12 Depth=5
	mov	x9, x24
	cbz	x23, .LBB1_11
.LBB1_16:                               //   in Loop: Header=BB1_12 Depth=5
	add	x8, x20, x8
	.p2align	5, , 16
.LBB1_17:                               //   Parent Loop BB1_4 Depth=1
                                        //     Parent Loop BB1_6 Depth=2
                                        //       Parent Loop BB1_8 Depth=3
                                        //         Parent Loop BB1_10 Depth=4
                                        //           Parent Loop BB1_12 Depth=5
                                        // =>          This Inner Loop Header: Depth=6
	ldr	s1, [x8, x9, lsl #2]
	ldr	s2, [x27, x9, lsl #2]
	fmadd	s1, s0, s1, s2
	str	s1, [x27, x9, lsl #2]
	add	x9, x9, #1
	cmp	x9, x7
	b.lt	.LBB1_17
	b	.LBB1_11
.LBB1_18:
	.cfi_def_cfa wsp, 144
	ldp	x20, x19, [sp, #128]            // 16-byte Folded Reload
	ldp	x22, x21, [sp, #112]            // 16-byte Folded Reload
	ldp	x24, x23, [sp, #96]             // 16-byte Folded Reload
	ldp	x26, x25, [sp, #80]             // 16-byte Folded Reload
	ldp	x28, x27, [sp, #64]             // 16-byte Folded Reload
	ldp	x29, x30, [sp, #48]             // 16-byte Folded Reload
	add	sp, sp, #144
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
	subs	w10, w0, w2
                                        // kill: def $w3 killed $w3 def $x3
	b.lt	.LBB2_37
// %bb.1:
	sub	w8, w1, w3
	tbnz	w8, #31, .LBB2_37
// %bb.2:
	add	w21, w8, #1
	cmp	w2, #0
	mov	x19, x6
	b.le	.LBB2_23
// %bb.3:
	cmp	w3, #0
	b.le	.LBB2_25
// %bb.4:
	mov	w12, w3
	sub	x13, x12, #1
	add	w10, w10, #1
	and	x15, x12, #0x7ffffff8
	and	x16, x12, #0x3
	add	x17, x5, #16
	ubfiz	x18, x3, #2, #32
	mov	x8, xzr
	mov	x9, xzr
	mov	w11, w2
	mov	w14, w1
	lsr	x0, x13, #32
	b	.LBB2_6
	.p2align	5, , 16
.LBB2_5:                                //   in Loop: Header=BB2_6 Depth=1
	add	x9, x9, #1
	add	x8, x8, x14
	cmp	x9, x10
	b.eq	.LBB2_37
.LBB2_6:                                // =>This Loop Header: Depth=1
                                        //     Child Loop BB2_8 Depth 2
                                        //       Child Loop BB2_10 Depth 3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	mul	w6, w21, w9
	mul	x2, x9, x14
	mov	x1, xzr
	mov	x7, x8
	add	x6, x19, w6, uxtw #2
	b	.LBB2_8
	.p2align	5, , 16
.LBB2_7:                                //   in Loop: Header=BB2_8 Depth=2
	str	s0, [x6, x1, lsl #2]
	add	x1, x1, #1
	add	x7, x7, #1
	cmp	x1, x21
	b.eq	.LBB2_5
.LBB2_8:                                //   Parent Loop BB2_6 Depth=1
                                        // =>  This Loop Header: Depth=2
                                        //       Child Loop BB2_10 Depth 3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	movi	d0, #0000000000000000
	add	x22, x2, x1
	mov	x20, xzr
	mov	x23, x7
	mov	x24, x5
	mov	x25, x17
	b	.LBB2_10
	.p2align	5, , 16
.LBB2_9:                                //   in Loop: Header=BB2_10 Depth=3
	add	x20, x20, #1
	add	x25, x25, x18
	add	x23, x23, x14
	add	x24, x24, x18
	cmp	x20, x11
	b.eq	.LBB2_7
.LBB2_10:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        // =>    This Loop Header: Depth=3
                                        //         Child Loop BB2_21 Depth 4
                                        //         Child Loop BB2_15 Depth 4
                                        //         Child Loop BB2_19 Depth 4
	cmp	w3, #8
	b.lo	.LBB2_12
// %bb.11:                              //   in Loop: Header=BB2_10 Depth=3
	madd	w26, w20, w14, w22
	add	w27, w26, w13
	cmp	w27, w26
	ccmp	x0, #0, #0, ge
	b.eq	.LBB2_20
.LBB2_12:                               //   in Loop: Header=BB2_10 Depth=3
	mov	x27, xzr
.LBB2_13:                               //   in Loop: Header=BB2_10 Depth=3
	cbz	x16, .LBB2_17
// %bb.14:                              //   in Loop: Header=BB2_10 Depth=3
	mov	x28, x16
	mov	x26, x27
	.p2align	5, , 16
.LBB2_15:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	w30, w23, w26
	ldr	s2, [x24, x26, lsl #2]
	add	x26, x26, #1
	subs	x28, x28, #1
	ldr	s1, [x4, w30, sxtw #2]
	fmadd	s0, s1, s2, s0
	b.ne	.LBB2_15
// %bb.16:                              //   in Loop: Header=BB2_10 Depth=3
	sub	x27, x27, x12
	cmn	x27, #4
	b.hi	.LBB2_9
	b	.LBB2_18
	.p2align	5, , 16
.LBB2_17:                               //   in Loop: Header=BB2_10 Depth=3
	mov	x26, x27
	sub	x27, x27, x12
	cmn	x27, #4
	b.hi	.LBB2_9
.LBB2_18:                               //   in Loop: Header=BB2_10 Depth=3
	add	x27, x24, x26, lsl #2
	.p2align	5, , 16
.LBB2_19:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	w28, w23, w26
	ldp	s2, s3, [x27]
	add	x26, x26, #4
	ldr	s1, [x4, w28, sxtw #2]
	add	w30, w28, #1
	cmp	x12, x26
	fmadd	s0, s1, s2, s0
	ldr	s1, [x4, w30, sxtw #2]
	add	w30, w28, #2
	add	w28, w28, #3
	fmadd	s0, s1, s3, s0
	ldr	s1, [x4, w30, sxtw #2]
	ldp	s2, s3, [x27, #8]
	add	x27, x27, #16
	fmadd	s0, s1, s2, s0
	ldr	s1, [x4, w28, sxtw #2]
	fmadd	s0, s1, s3, s0
	b.ne	.LBB2_19
	b	.LBB2_9
	.p2align	5, , 16
.LBB2_20:                               //   in Loop: Header=BB2_10 Depth=3
	movi	v2.4s, #128, lsl #24
	movi	v1.4s, #128, lsl #24
	mov	w26, w23
	mov	x27, x15
	mov	x28, x25
	mov	v2.s[0], v0.s[0]
	.p2align	5, , 16
.LBB2_21:                               //   Parent Loop BB2_6 Depth=1
                                        //     Parent Loop BB2_8 Depth=2
                                        //       Parent Loop BB2_10 Depth=3
                                        // =>      This Inner Loop Header: Depth=4
	add	x30, x4, w26, sxtw #2
	ldp	q4, q5, [x28, #-16]
	add	x28, x28, #32
	subs	x27, x27, #8
	add	w26, w26, #8
	ldp	q0, q3, [x30]
	fmla	v1.4s, v5.4s, v3.4s
	fmla	v2.4s, v4.4s, v0.4s
	b.ne	.LBB2_21
// %bb.22:                              //   in Loop: Header=BB2_10 Depth=3
	fadd	v0.4s, v1.4s, v2.4s
	cmp	x15, x12
	mov	x27, x15
	faddp	v0.4s, v0.4s, v0.4s
	faddp	s0, v0.2s
	b.eq	.LBB2_9
	b	.LBB2_13
.LBB2_23:
	add	w22, w10, #1
	ubfiz	x20, x21, #2, #32
	cmp	w22, #1
	b.ne	.LBB2_34
// %bb.24:
	mov	w8, wzr
	tbz	w22, #0, .LBB2_37
	b	.LBB2_38
.LBB2_25:
	rdvl	x12, #1
	mov	w13, #-8                        // =0xfffffff8
	cnth	x11
	mov	z0.s, #0                        // =0x0
	add	w10, w10, #1
	mov	w8, wzr
	mov	x9, xzr
	lsr	x12, x12, #4
	ptrue	p0.s
	mul	x12, x12, x13
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
	ubfiz	x13, x8, #2, #32
	cmp	x11, x21
	b.ls	.LBB2_29
// %bb.28:                              //   in Loop: Header=BB2_27 Depth=1
	mov	x14, xzr
	b	.LBB2_32
	.p2align	5, , 16
.LBB2_29:                               //   in Loop: Header=BB2_27 Depth=1
	add	x16, x19, x13
	and	x14, x12, x21
	mov	x15, xzr
	addvl	x17, x16, #1
	.p2align	5, , 16
.LBB2_30:                               //   Parent Loop BB2_27 Depth=1
                                        // =>  This Inner Loop Header: Depth=2
	st1w	{ z0.s }, p0, [x16, x15, lsl #2]
	st1w	{ z0.s }, p0, [x17, x15, lsl #2]
	inch	x15
	cmp	x14, x15
	b.ne	.LBB2_30
// %bb.31:                              //   in Loop: Header=BB2_27 Depth=1
	cmp	x14, x21
	b.eq	.LBB2_26
.LBB2_32:                               //   in Loop: Header=BB2_27 Depth=1
	add	x13, x13, x14, lsl #2
	sub	x14, x21, x14
	add	x13, x19, x13
	.p2align	5, , 16
.LBB2_33:                               //   Parent Loop BB2_27 Depth=1
                                        // =>  This Inner Loop Header: Depth=2
	str	wzr, [x13], #4
	subs	x14, x14, #1
	b.ne	.LBB2_33
	b	.LBB2_26
.LBB2_34:
	and	x8, x22, #0xfffffffe
	lsl	w25, w21, #1
	mov	x23, xzr
	mov	w24, wzr
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
