//===- SveVectorizeHint.cpp ----------------------------------------------===//
//
// A target-aware vectorization *policy* pass for Arm SVE, written as an
// out-of-tree LLVM 18 plugin (new PassManager).
//
// Target: NVIDIA Grace (Arm Neoverse V2, 128-bit SVE2) and other SVE
// CPUs such as AWS Graviton3 (Neoverse V1, 256-bit SVE).
//
// LLVM's loop vectorizer makes two decisions this pass can influence:
//
//   (a) Fixed-width NEON vs. scalable SVE vectors.
//       Forcing SVE is not automatically a win. On a CPU whose SVE
//       registers are no wider than NEON (Grace: both 128-bit), NEON
//       loops can use load/store-pair instructions (ldp/stp) and run
//       *faster* than the SVE equivalent - measured in this repo at
//       1.73 vs 2.05 cycles/iteration for the tiled GEMM inner loop.
//       So the pass asks TargetTransformInfo how wide SVE is *for
//       tuning* on the CPU being compiled for, and only forces scalable
//       vectors when they are genuinely wider than NEON (e.g. 256-bit on
//       Neoverse V1), or when SVE-only features (gathers) are needed.
//
//   (b) Whether a floating-point reduction (acc += a*b) may be
//       reassociated. Without -ffast-math, LLVM must keep the additions
//       in source order, which serialises the loop on the FMA latency.
//       -ffast-math fixes that, but for the *whole* translation unit.
//       In relaxed mode this pass instead sets the `reassoc` fast-math
//       flag only on the reduction chain of the loops it selects -
//       scoped fast-math - and lets LLVM's own cost model pick the best
//       code (interleaved accumulators, SVE, ...).
//
// Analysis per innermost loop:
//   - shape: no opaque calls / switches / indirect branches,
//   - every load/store classified with ScalarEvolution as unit-stride,
//     strided (needs gather/scatter) or loop-invariant,
//   - floating-point reductions found with RecurrenceDescriptor.
//
// Options (pass to clang as -mllvm <opt>; see README):
//   -sve-hint-mode=strict|relaxed  strict (default) never changes FP
//                                  results; relaxed enables scoped
//                                  reassociation of reductions.
//   -sve-hint-gathers=auto|on|off  force SVE on loops that need
//                                  gather/scatter? auto (default): only
//                                  when SVE is wider than NEON - measured
//                                  1.74x vs 1.91x (lose) on 128-bit
//                                  Grace, 5.45x vs 1.95x (win) on 256-bit
//                                  Graviton3 for the naive GEMM.
//   -sve-hint-force-scalable       force SVE even when it is no wider
//                                  than NEON (for experiments).
//
//===----------------------------------------------------------------===//

#include "llvm/Analysis/IVDescriptors.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/LoopUtils.h"

using namespace llvm;

namespace {

enum class HintMode { Strict, Relaxed };

static cl::opt<HintMode> Mode(
    "sve-hint-mode", cl::desc("Floating-point policy"),
    cl::init(HintMode::Strict),
    cl::values(clEnumValN(HintMode::Strict, "strict",
                          "Never change floating-point results"),
               clEnumValN(HintMode::Relaxed, "relaxed",
                          "Scoped reassociation of FP reductions")));

enum class GatherPolicy { Auto, On, Off };

static cl::opt<GatherPolicy> Gathers(
    "sve-hint-gathers", cl::desc("When to force SVE on loops that need "
                                 "gather/scatter"),
    cl::init(GatherPolicy::Auto),
    cl::values(
        clEnumValN(GatherPolicy::Auto, "auto",
                   "Only when SVE is wider than NEON on the target CPU"),
        clEnumValN(GatherPolicy::On, "on", "Always"),
        clEnumValN(GatherPolicy::Off, "off", "Never")));

static cl::opt<bool> ForceScalable(
    "sve-hint-force-scalable", cl::init(false),
    cl::desc("Force SVE even where it is no wider than NEON"));

static cl::opt<bool> Quiet("sve-hint-quiet", cl::init(false),
                           cl::desc("Don't print per-loop decisions"));

//===-- Loop analysis -----------------------------------------------===//

struct LoopFacts {
  unsigned UnitStride = 0, Strided = 0, Invariant = 0, Unknown = 0;
  SmallVector<PHINode *, 2> FPReductions;
  const char *BadShape = nullptr; // non-null: why it isn't data-parallel
};

static void classifyAccess(Value *Ptr, Type *ElemTy, Loop *L,
                           ScalarEvolution &SE, const DataLayout &DL,
                           LoopFacts &R) {
  const SCEV *S = SE.getSCEV(Ptr);
  if (SE.isLoopInvariant(S, L)) {
    R.Invariant++;
    return;
  }
  auto *AR = dyn_cast<SCEVAddRecExpr>(S);
  if (!AR || AR->getLoop() != L || !AR->isAffine()) {
    R.Unknown++;
    return;
  }
  int64_t Elem = (int64_t)DL.getTypeAllocSize(ElemTy);
  if (auto *C = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE))) {
    int64_t Step = C->getAPInt().getSExtValue();
    if (Step == Elem || Step == -Elem) {
      R.UnitStride++;
      return;
    }
  }
  // Affine with a non-unit or runtime stride, e.g. B[k*n + j] walking
  // down a column as k varies: vectorizing it needs gather/scatter.
  R.Strided++;
}

static LoopFacts analyzeLoop(Loop *L, ScalarEvolution &SE,
                             const DataLayout &DL) {
  LoopFacts R;
  for (BasicBlock *BB : L->blocks())
    for (Instruction &I : *BB) {
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (!isa<IntrinsicInst>(CB))
          R.BadShape = "contains a call";
      } else if (isa<SwitchInst>(&I) || isa<IndirectBrInst>(&I)) {
        R.BadShape = "non-trivial control flow";
      } else if (auto *Ld = dyn_cast<LoadInst>(&I)) {
        classifyAccess(Ld->getPointerOperand(), Ld->getType(), L, SE, DL, R);
      } else if (auto *St = dyn_cast<StoreInst>(&I)) {
        classifyAccess(St->getPointerOperand(),
                       St->getValueOperand()->getType(), L, SE, DL, R);
      }
    }
  for (PHINode &Phi : L->getHeader()->phis()) {
    RecurrenceDescriptor RD;
    if (Phi.getType()->isFloatingPointTy() &&
        RecurrenceDescriptor::isReductionPHI(&Phi, L, RD))
      R.FPReductions.push_back(&Phi);
  }
  return R;
}

//===-- Transformations ---------------------------------------------===//

// Scoped fast-math: allow reassociation on every FP operation that sits
// on the reduction cycle  phi -> ... -> phi  inside this loop - and
// nowhere else. This is exactly the permission the vectorizer needs to
// split the accumulator into independent partial sums.
static unsigned allowReassocOnReduction(PHINode *Phi, Loop *L) {
  SmallPtrSet<Instruction *, 16> Seen;
  SmallVector<Instruction *, 16> Work{Phi};
  unsigned Marked = 0;
  while (!Work.empty()) {
    Instruction *I = Work.pop_back_val();
    for (User *U : I->users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || !L->contains(UI) || UI == Phi || !Seen.insert(UI).second)
        continue;
      if (isa<FPMathOperator>(UI) && !UI->hasAllowReassoc()) {
        UI->setHasAllowReassoc(true);
        Marked++;
      }
      Work.push_back(UI);
    }
  }
  return Marked;
}

static void hintScalable(Loop *L, unsigned MinElts) {
  addStringMetadataToLoop(L, "llvm.loop.vectorize.enable", 1);
  addStringMetadataToLoop(L, "llvm.loop.vectorize.scalable.enable", 1);
  addStringMetadataToLoop(L, "llvm.loop.vectorize.width", MinElts);
}

static bool alreadyHasVectorizeDecision(Loop *L) {
  return L->getLoopID() &&
         (findStringMetadataForLoop(L, "llvm.loop.vectorize.enable") ||
          findStringMetadataForLoop(L, "llvm.loop.vectorize.width") ||
          findStringMetadataForLoop(L, "llvm.loop.vectorize.scalable.enable"));
}

static void collectInnermost(ArrayRef<Loop *> Loops,
                             SmallVectorImpl<Loop *> &Out) {
  for (Loop *L : Loops) {
    if (L->getSubLoops().empty())
      Out.push_back(L);
    else
      collectInnermost(L->getSubLoops(), Out);
  }
}

static std::string where(Loop *L) {
  if (DebugLoc DL = L->getStartLoc())
    return (Twine(DL->getFilename()) + ":" + Twine(DL.getLine())).str();
  return "<no debug info>";
}

//===-- The pass ----------------------------------------------------===//

struct SveVectorizeHintPass : PassInfoMixin<SveVectorizeHintPass> {
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &FAM) {
    if (F.isDeclaration())
      return PreservedAnalyses::all();

    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
    auto &TTI = FAM.getResult<TargetIRAnalysis>(F);
    const DataLayout &DL = F.getParent()->getDataLayout();

    // How wide are vectors on *this* CPU? Fixed = NEON. For SVE the
    // architectural size is vscale x 128 bits; vscale-for-tuning is the
    // value the CPU actually implements (Neoverse V2: 1, V1: 2).
    unsigned FixedBits =
        TTI.getRegisterBitWidth(TargetTransformInfo::RGK_FixedWidthVector)
            .getFixedValue();
    unsigned SVEBits = 0;
    if (TTI.supportsScalableVectors())
      SVEBits = TTI.getRegisterBitWidth(
                       TargetTransformInfo::RGK_ScalableVector)
                    .getKnownMinValue() *
                TTI.getVScaleForTuning().value_or(1);
    bool SVEIsWider = SVEBits > FixedBits;
    bool UseGathers = Gathers == GatherPolicy::On ||
                      (Gathers == GatherPolicy::Auto && SVEIsWider);

    SmallVector<Loop *, 8> Inner;
    collectInnermost(SmallVector<Loop *, 8>(LI.begin(), LI.end()), Inner);

    bool Changed = false;
    for (Loop *L : Inner) {
      std::string Decision;
      raw_string_ostream OS(Decision);
      LoopFacts R;

      if (!L->isLoopSimplifyForm()) {
        OS << "skip: not in loop-simplify form";
      } else if (alreadyHasVectorizeDecision(L)) {
        OS << "skip: user already gave a vectorize pragma";
      } else if ((R = analyzeLoop(L, SE, DL)).BadShape) {
        OS << "skip: " << R.BadShape;
      } else {
        bool HasFPRed = !R.FPReductions.empty();
        bool Relaxed = Mode == HintMode::Relaxed;

        // (b) scoped reassociation of FP reductions.
        if (HasFPRed && Relaxed) {
          unsigned N = 0;
          for (PHINode *P : R.FPReductions)
            N += allowReassocOnReduction(P, L);
          OS << "reassoc(" << N << " ops); ";
          Changed |= N > 0;
        }

        // (a) should we force scalable (SVE) vectors?
        const char *Why = nullptr, *WhyNot = nullptr;
        if (R.Unknown)
          WhyNot = "access pattern not analysable by SCEV";
        else if (R.UnitStride + R.Strided == 0)
          WhyNot = "no loop-varying array accesses";
        else if (HasFPRed && !Relaxed)
          // An explicit vectorize hint also licenses LLVM to reorder FP
          // reductions (LoopVectorizeHints::allowReordering), so strict
          // mode must not hint these loops at all.
          WhyNot = "FP reduction; strict mode keeps results bit-exact";
        else if (R.Strided && !UseGathers)
          WhyNot = SVEIsWider ? "needs gather/scatter (-sve-hint-gathers=off)"
                              : "needs gathers; at this SVE width they lose "
                                "to scalar code";
        else if (R.Strided)
          Why = "SVE gathers (NEON has none)";
        else if (SVEIsWider)
          Why = "SVE is wider than NEON on this CPU";
        else if (ForceScalable)
          Why = "-sve-hint-force-scalable";
        else
          WhyNot = "SVE no wider than NEON here; NEON ldp/stp is cheaper";

        if (Why) {
          hintScalable(L, /*MinElts=*/4);
          Changed = true;
          OS << "FORCE SVE (" << Why << ")";
        } else {
          OS << "leave width to cost model (" << WhyNot << ")";
        }
      }

      if (!Quiet)
        errs() << "[sve-vectorize-hint] " << F.getName() << " @ "
               << where(L) << " [unit=" << R.UnitStride
               << " strided=" << R.Strided << " fp-red="
               << R.FPReductions.size() << " | NEON=" << FixedBits
               << "b SVE=" << SVEBits << "b] -> " << OS.str() << "\n";
    }

    if (!Changed)
      return PreservedAnalyses::all();
    // Only metadata and fast-math flags changed: CFG and loop structure
    // are untouched.
    PreservedAnalyses PA;
    PA.preserveSet<CFGAnalyses>();
    PA.preserve<LoopAnalysis>();
    return PA;
  }

  static bool isRequired() { return true; }
};

} // namespace

PassPluginLibraryInfo getSveVectorizeHintPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "SveVectorizeHint", LLVM_VERSION_STRING,
          [](PassBuilder &PB) {
            // Runs inside `clang -O2/-O3 -fpass-plugin=...`, right
            // before LLVM's loop vectorizer.
            PB.registerVectorizerStartEPCallback(
                [](FunctionPassManager &FPM, OptimizationLevel) {
                  FPM.addPass(SveVectorizeHintPass());
                });
            // Also by name: opt -passes=sve-vectorize-hint
            PB.registerPipelineParsingCallback(
                [](StringRef Name, FunctionPassManager &FPM,
                   ArrayRef<PassBuilder::PipelineElement>) {
                  if (Name == "sve-vectorize-hint") {
                    FPM.addPass(SveVectorizeHintPass());
                    return true;
                  }
                  return false;
                });
          }};
}

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return getSveVectorizeHintPluginInfo();
}
