; Policy tests for the sve-vectorize-hint pass.
;
; Four loops, each compiled for NVIDIA Grace (neoverse-v2, 128-bit SVE) and
; AWS Graviton3 (neoverse-v1, 256-bit SVE), in strict and relaxed mode:
;
;                  contiguous   dot (FP red.)   column_dot (gather)   has_call
;   V2 strict      -            -               -                     -
;   V2 relaxed     -            reassoc         reassoc               -
;   V1 strict      SVE          -               -                     -
;   V1 relaxed     SVE          reassoc + SVE   reassoc + SVE         -
;
; ("-" = pass leaves the loop alone; "SVE" = scalable-vectorize metadata.)

; RUN: %opt_sve -mcpu=neoverse-v2 -sve-hint-mode=strict  %s | FileCheck %s --check-prefixes=ALL,V2,STRICT
; RUN: %opt_sve -mcpu=neoverse-v2 -sve-hint-mode=relaxed %s | FileCheck %s --check-prefixes=ALL,V2,RELAXED
; RUN: %opt_sve -mcpu=neoverse-v1 -sve-hint-mode=strict  %s | FileCheck %s --check-prefixes=ALL,V1,STRICT
; RUN: %opt_sve -mcpu=neoverse-v1 -sve-hint-mode=relaxed %s | FileCheck %s --check-prefixes=ALL,V1,V1R,RELAXED
; Explicit overrides: gathers off on Graviton3 drops the column_dot hint only.
; RUN: %opt_sve -mcpu=neoverse-v1 -sve-hint-mode=relaxed -sve-hint-gathers=off %s | FileCheck %s --check-prefix=NOGATHER

; void contiguous(int n, float a, const float *restrict b, float *restrict c)
;   { for (int i = 0; i < n; i++) c[i] += a * b[i]; }
; ALL-LABEL: define {{.*}} @contiguous(
; ALL-NOT:   reassoc
; V2-NOT:    !llvm.loop
; V1:        br i1 {{.*}}, !llvm.loop [[SVE:![0-9]+]]

; float dot(int n, const float *restrict a, const float *restrict b)
;   { float s = 0; for (...) s += a[i] * b[i]; return s; }
; ALL-LABEL: define {{.*}} @dot(
; STRICT-NOT: reassoc
; RELAXED:   call reassoc float @llvm.fmuladd.f32
; V2-NOT:    !llvm.loop
; STRICT-NOT: !llvm.loop
; V1R:       br i1 {{.*}}, !llvm.loop

; float column_dot(...) { ... s += a[k] * b[k * n]; ... }   // strided
; ALL-LABEL: define {{.*}} @column_dot(
; STRICT-NOT: reassoc
; RELAXED:   call reassoc float @llvm.fmuladd.f32
; V2-NOT:    !llvm.loop
; STRICT-NOT: !llvm.loop
; V1R:       br i1 {{.*}}, !llvm.loop
; NOGATHER-LABEL: define {{.*}} @column_dot(
; NOGATHER-NOT: !llvm.loop
; NOGATHER-LABEL: define {{.*}} @has_call(

; void has_call(int n, const float *restrict b) { for (...) ext(b[i]); }
; ALL-LABEL: define {{.*}} @has_call(
; ALL-NOT:   !llvm.loop
; ALL-NOT:   reassoc

; V1-DAG: [[SVE]] = distinct !{[[SVE]], [[EN:![0-9]+]], [[SC:![0-9]+]], [[W:![0-9]+]]}
; V1-DAG: [[EN]] = !{!"llvm.loop.vectorize.enable", i32 1}
; V1-DAG: [[SC]] = !{!"llvm.loop.vectorize.scalable.enable", i32 1}
; V1-DAG: [[W]] = !{!"llvm.loop.vectorize.width", i32 4}

target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @contiguous(i32 noundef %0, float noundef %1, ptr noalias nocapture noundef readonly %2, ptr noalias nocapture noundef %3) {
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %4
  %7 = zext nneg i32 %0 to i64
  br label %9

8:                                                ; preds = %9, %4
  ret void

9:                                                ; preds = %6, %9
  %10 = phi i64 [ 0, %6 ], [ %16, %9 ]
  %11 = getelementptr inbounds float, ptr %2, i64 %10
  %12 = load float, ptr %11, align 4
  %13 = getelementptr inbounds float, ptr %3, i64 %10
  %14 = load float, ptr %13, align 4
  %15 = tail call float @llvm.fmuladd.f32(float %1, float %12, float %14)
  store float %15, ptr %13, align 4
  %16 = add nuw nsw i64 %10, 1
  %17 = icmp eq i64 %16, %7
  br i1 %17, label %8, label %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float)

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local float @dot(i32 noundef %0, ptr noalias nocapture noundef readonly %1, ptr noalias nocapture noundef readonly %2) {
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %0 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi float [ 0.000000e+00, %3 ], [ %16, %9 ]
  ret float %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %17, %9 ]
  %11 = phi float [ 0.000000e+00, %5 ], [ %16, %9 ]
  %12 = getelementptr inbounds float, ptr %1, i64 %10
  %13 = load float, ptr %12, align 4
  %14 = getelementptr inbounds float, ptr %2, i64 %10
  %15 = load float, ptr %14, align 4
  %16 = tail call float @llvm.fmuladd.f32(float %13, float %15, float %11)
  %17 = add nuw nsw i64 %10, 1
  %18 = icmp eq i64 %17, %6
  br i1 %18, label %7, label %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local float @column_dot(i32 noundef %0, ptr noalias nocapture noundef readonly %1, ptr noalias nocapture noundef readonly %2) {
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = zext nneg i32 %0 to i64
  %7 = zext nneg i32 %0 to i64
  br label %10

8:                                                ; preds = %10, %3
  %9 = phi float [ 0.000000e+00, %3 ], [ %18, %10 ]
  ret float %9

10:                                               ; preds = %5, %10
  %11 = phi i64 [ 0, %5 ], [ %19, %10 ]
  %12 = phi float [ 0.000000e+00, %5 ], [ %18, %10 ]
  %13 = getelementptr inbounds float, ptr %1, i64 %11
  %14 = load float, ptr %13, align 4
  %15 = mul nsw i64 %11, %6
  %16 = getelementptr inbounds float, ptr %2, i64 %15
  %17 = load float, ptr %16, align 4
  %18 = tail call float @llvm.fmuladd.f32(float %14, float %17, float %12)
  %19 = add nuw nsw i64 %11, 1
  %20 = icmp eq i64 %19, %7
  br i1 %20, label %8, label %10
}

; Function Attrs: nounwind uwtable
define dso_local void @has_call(i32 noundef %0, ptr noalias nocapture noundef readonly %1) {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %0 to i64
  br label %7

6:                                                ; preds = %7, %2
  ret void

7:                                                ; preds = %4, %7
  %8 = phi i64 [ 0, %4 ], [ %11, %7 ]
  %9 = getelementptr inbounds float, ptr %1, i64 %8
  %10 = load float, ptr %9, align 4
  tail call void @ext(float noundef %10) #5
  %11 = add nuw nsw i64 %8, 1
  %12 = icmp eq i64 %11, %5
  br i1 %12, label %6, label %7
}

declare void @ext(float noundef)



