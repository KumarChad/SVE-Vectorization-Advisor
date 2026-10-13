#!/usr/bin/env python3
"""
One-command benchmark for the SveVectorizeHint pass, targeting NVIDIA
Grace (Arm Neoverse V2).

For every compiler variant it:
  1. compiles the kernels for aarch64 / -mcpu=neoverse-v2,
  2. links a static test binary,
  3. CORRECTNESS: runs every kernel under QEMU at SVE vector lengths
     128/256/512/2048 bits and compares against a scalar reference,
  4. PROFILE: runs each kernel under QEMU at 128-bit SVE (Grace's vector
     length) with one-instruction-per-block tracing, giving the *exact*
     number of times every instruction executed,
  5. CYCLES: splits the kernel into basic blocks, asks llvm-mca's
     Neoverse V2 model for each block's steady-state cycles/iteration,
     and sums  exec_count(block) * cycles(block)  -> estimated cycles.

Writes results/results.md, results/results.json, and per-variant
assembly + pass logs into results/.

usage: python3 bench/run_bench.py [--size N] [--quick]
"""

import argparse
import collections
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src", "kernels")
BUILD = os.path.join(ROOT, "build")
RESULTS = os.path.join(ROOT, "results")
PLUGIN = os.path.join(BUILD, "libSveVectorizeHint.so")

# (llvm -mcpu name, SVE vector length in bits, the machine it is)
CPUS = [
    ("neoverse-v2", 128, "NVIDIA Grace"),
    ("neoverse-v1", 256, "AWS Graviton3"),
]
GCC = "aarch64-linux-gnu-gcc"
KERNELS = ["gemm_naive", "gemm_tiled", "conv2d"]
VECTOR_LENGTHS = [128, 256, 512, 2048]  # bits, for correctness checks
PLUGIN_FLAGS = [f"-fplugin={PLUGIN}", f"-fpass-plugin={PLUGIN}"]


def variants(cpu):
    clang = ["clang", "--target=aarch64-linux-gnu", f"-mcpu={cpu}", "-O3"]
    hint = clang + PLUGIN_FLAGS
    return [
        {"name": "clang -O3", "id": "clang_O3", "cc": clang},
        {"name": "+pass strict", "id": "pass_strict",
         "cc": hint + ["-mllvm", "-sve-hint-mode=strict"]},
        {"name": "+pass relaxed (default policy)", "id": "pass_relaxed",
         "cc": hint + ["-mllvm", "-sve-hint-mode=relaxed"]},
        {"name": "+pass relaxed, gathers=off", "id": "pass_relaxed_nogather",
         "cc": hint + ["-mllvm", "-sve-hint-mode=relaxed",
                       "-mllvm", "-sve-hint-gathers=off"]},
        {"name": "+pass relaxed, force SVE everywhere", "id": "pass_force",
         "cc": hint + ["-mllvm", "-sve-hint-mode=relaxed",
                       "-mllvm", "-sve-hint-gathers=on",
                       "-mllvm", "-sve-hint-force-scalable"]},
        {"name": "clang -O3 -ffast-math", "id": "clang_fastmath",
         "cc": clang + ["-ffast-math"]},
        {"name": "gcc-13 -O3", "id": "gcc_O3",
         "cc": [GCC, f"-mcpu={cpu}", "-O3"]},
    ]


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        sys.exit(f"command failed: {' '.join(cmd)}\n{r.stdout}\n{r.stderr}")
    return r


def build_plugin():
    if not os.path.exists(os.path.join(BUILD, "CMakeCache.txt")):
        llvm_dir = run(["llvm-config-18", "--cmakedir"]).stdout.strip()
        run(["cmake", "-S", ROOT, "-B", BUILD, f"-DLLVM_DIR={llvm_dir}",
             "-DCMAKE_CXX_COMPILER=clang++"])
    run(["cmake", "--build", BUILD])


def build_variant(v, cpu, work):
    """Compile kernels.c for variant v, link the harness. Returns paths."""
    tag = f"{cpu}_{v['id']}"
    kobj = os.path.join(work, f"kernels_{tag}.o")
    asm = os.path.join(RESULTS, "asm", f"{tag}.s")
    common = v["cc"] + ["-I", SRC]
    r = run(common + ["-g", "-c", os.path.join(SRC, "kernels.c"), "-o", kobj])
    pass_log = "\n".join(l for l in r.stderr.splitlines()
                         if "sve-vectorize-hint" in l)
    run(common + ["-S", os.path.join(SRC, "kernels.c"), "-o", asm])
    exe = os.path.join(work, f"bench_{tag}")
    run([GCC, "-static", os.path.join(work, "harness.o"),
         os.path.join(work, "ref.o"), kobj, "-lm", "-o", exe])
    return exe, asm, pass_log


def qemu(vl_bits, *extra):
    return ["qemu-aarch64", *extra, "-cpu",
            f"max,sve-default-vector-length={vl_bits // 8}"]


def check_correctness(exe, kernel, size):
    out = []
    for vl in VECTOR_LENGTHS:
        r = subprocess.run(qemu(vl) + [exe, kernel, str(size)],
                           capture_output=True, text=True)
        fields = dict(kv.split("=") for kv in r.stdout.split())
        fields["ok"] = r.returncode == 0
        out.append(fields)
    return out


TRACE_RE = re.compile(r"\[[0-9a-f]+/([0-9a-f]+)/[0-9a-f]+/[0-9a-f]+\] (\S+)")


def profile(exe, kernel, size, vl_bits):
    """Exact executed-instruction count per PC inside `kernel`."""
    cmd = qemu(vl_bits, "-one-insn-per-tb", "-d", "exec,nochain",
               "-D", "/dev/stderr") + [exe, kernel, str(size)]
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL,
                         stderr=subprocess.PIPE, text=True, bufsize=1 << 20)
    counts = collections.Counter()
    for line in p.stderr:
        if line.endswith(" " + kernel + "\n"):
            m = TRACE_RE.search(line)
            if m and m.group(2) == kernel:
                counts[int(m.group(1), 16)] += 1
    p.wait()
    return counts


OBJDUMP_RE = re.compile(r"^\s*([0-9a-f]+):\s+(.*)$")
BRANCH_MNEMONICS = ("b", "b.", "bl", "cbz", "cbnz", "tbz", "tbnz", "ret",
                    "br", "blr")


def is_branch(mnemonic):
    return (mnemonic in ("b", "bl", "ret", "br", "blr", "cbz", "cbnz",
                         "tbz", "tbnz") or mnemonic.startswith("b."))


def disassemble(exe, symbol):
    r = run(["llvm-objdump-18", "-d", "--no-show-raw-insn",
             "--mattr=+sve2", f"--disassemble-symbols={symbol}", exe])
    insns = []
    for line in r.stdout.splitlines():
        m = OBJDUMP_RE.match(line)
        if m and m.group(2).strip():
            text = m.group(2).split("//")[0].strip()
            insns.append((int(m.group(1), 16), text))
    return insns


def split_blocks(insns):
    targets = set()
    for _, text in insns:
        mnem = text.split()[0]
        if is_branch(mnem):
            m = re.search(r"0x([0-9a-f]+)", text)
            if m:
                targets.add(int(m.group(1), 16))
    blocks, cur = [], []
    for i, (pc, text) in enumerate(insns):
        if cur and pc in targets:
            blocks.append(cur)
            cur = []
        cur.append((pc, text))
        if is_branch(text.split()[0]):
            blocks.append(cur)
            cur = []
    if cur:
        blocks.append(cur)
    return blocks


POST_INDEX_RE = re.compile(r"^(.*)\[(x\d+|sp)\],\s*(#-?(?:0x)?[0-9a-f]+|x\d+)$")
PRE_INDEX_RE = re.compile(r"^(.*)\[(x\d+|sp),\s*(#-?(?:0x)?[0-9a-f]+)\]!$")


def split_writeback(text):
    """Rewrite pre/post-indexed loads/stores as a plain access + an add.

    llvm-mca (LLVM 18, Neoverse V2 model) makes the base-register writeback
    of e.g. `stp q4, q5, [x28], #32` available only when the *whole* store
    completes - i.e. after its data operands are ready. That invents a
    loop-carried chain load -> fma -> store -> pointer -> next load that
    real hardware doesn't have (the AGU computes the writeback without
    waiting for store data). Splitting the update into an explicit `add`
    keeps the address dependency but drops the fake data dependency.
    True dependencies (e.g. an FP accumulator chain) are untouched.
    """
    m = POST_INDEX_RE.match(text)
    if m:
        op, base, inc = m.groups()
        inc = inc.lstrip("#")
        return [f"{op}[{base}]", f"add {base}, {base}, {inc if inc.startswith('x') else '#' + inc}"]
    m = PRE_INDEX_RE.match(text)
    if m:
        op, base, inc = m.groups()
        return [f"add {base}, {base}, {inc}", f"{op}[{base}]"]
    return [text]


def mca_cycles_per_iter(block, cache, cpu):
    """Steady-state cycles for one execution of `block` on Neoverse V2."""
    lines = []
    for _, text in block:
        mnem = text.split()[0]
        if is_branch(mnem):
            # llvm-mca can't resolve absolute addresses; point branch
            # targets at a local label (a branch's cost doesn't depend on
            # where it goes). Only touch branches - immediates elsewhere
            # (e.g. [x9, #-0x10]) must stay as they are.
            text = re.sub(r"0x[0-9a-f]+(\s*<[^>]*>)?", ".Lbb", text)
            lines.append("\t" + text)
        else:
            lines.extend("\t" + t for t in split_writeback(text))
    src = ".Lbb:\n" + "\n".join(lines) + "\n"
    key = (cpu, src)
    if key in cache:
        return cache[key]
    r = subprocess.run(
        ["llvm-mca-18", "-mtriple=aarch64-linux-gnu", f"-mcpu={cpu}",
         "-iterations=200", "-mattr=+sve2"],
        input=src, capture_output=True, text=True)
    m = re.search(r"Total Cycles:\s+(\d+)", r.stdout)
    if r.returncode != 0 or not m:
        val = (float(len(block)), False)  # fallback: 1 cycle/instruction
    else:
        val = (int(m.group(1)) / 200.0, True)
    cache[key] = val
    return val


def estimate(exe, kernel, counts, mca_cache, cpu):
    blocks = split_blocks(disassemble(exe, kernel))
    total_cycles, total_insns, fallbacks = 0.0, 0, 0
    hottest = None
    for b in blocks:
        execs = counts.get(b[0][0], 0)
        if not execs:
            continue
        cyc, ok = mca_cycles_per_iter(b, mca_cache, cpu)
        fallbacks += 0 if ok else 1
        total_cycles += execs * cyc
        total_insns += execs * len(b)
        if hottest is None or execs * cyc > hottest[0]:
            hottest = (execs * cyc, b, execs, cyc)
    return {
        "dyn_insns": total_insns,
        "dyn_insns_traced": sum(counts.values()),
        "est_cycles": total_cycles,
        "mca_fallback_blocks": fallbacks,
        "hot_block": [t for _, t in hottest[1]] if hottest else [],
        "hot_block_execs": hottest[2] if hottest else 0,
        "hot_block_cycles_per_iter": hottest[3] if hottest else 0,
        "uses_sve": any(re.search(r"\bz\d+\.", t) for _, t in hottest[1])
        if hottest else False,
        "uses_neon": any(re.search(r"\bv\d+\.\d*[sbhd]", t)
                         for _, t in hottest[1]) if hottest else False,
    }


def vec_kind(e):
    if e["uses_sve"]:
        return "SVE"
    if e["uses_neon"]:
        return "NEON"
    return "scalar"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=96,
                    help="matrix / image edge length (default 96)")
    ap.add_argument("--cpu", choices=[c[0] for c in CPUS],
                    help="only benchmark this CPU")
    ap.add_argument("--quick", action="store_true",
                    help="correctness only; skip the per-instruction profile")
    args = ap.parse_args()

    for tool in ["clang", GCC, "qemu-aarch64", "llvm-mca-18",
                 "llvm-objdump-18", "cmake"]:
        if not shutil.which(tool):
            sys.exit(f"missing tool: {tool} (see README 'Setup')")

    os.makedirs(os.path.join(RESULTS, "asm"), exist_ok=True)
    print("building pass plugin ...", flush=True)
    build_plugin()

    work = tempfile.mkdtemp(prefix="svebench-")
    # Reference + harness: built once, for baseline Armv9 + SVE2.
    base = ["clang", "--target=aarch64-linux-gnu", "-march=armv9-a+sve2",
            "-I", SRC]
    run(base + ["-O2", "-fno-vectorize", "-fno-slp-vectorize", "-c",
                os.path.join(SRC, "reference.c"), "-o",
                os.path.join(work, "ref.o")])
    run(base + ["-O2", "-c", os.path.join(SRC, "harness.c"), "-o",
                os.path.join(work, "harness.o")])

    cpus = [c for c in CPUS if not args.cpu or c[0] == args.cpu]
    results, mca_cache, pass_logs = [], {}, {}
    for cpu, vl, machine in cpus:
        for v in variants(cpu):
            print(f"[{cpu}] {v['name']}: compiling", flush=True)
            exe, asm, plog = build_variant(v, cpu, work)
            if plog:
                pass_logs[f"{cpu} ({machine}) / {v['name']}"] = plog
            for k in KERNELS:
                row = {"cpu": cpu, "machine": machine, "profile_vl": vl,
                       "variant": v["name"], "variant_id": v["id"],
                       "kernel": k, "size": args.size,
                       "cmd": " ".join(os.path.basename(c) if c.startswith("/") or "=" in c and "/" in c else c
                                       for c in v["cc"])}
                row["correctness"] = check_correctness(exe, k, args.size)
                if not args.quick:
                    counts = profile(exe, k, args.size, vl)
                    row.update(estimate(exe, k, counts, mca_cache, cpu))
                results.append(row)
    shutil.rmtree(work, ignore_errors=True)

    with open(os.path.join(RESULTS, "results.json"), "w") as f:
        json.dump(results, f, indent=1)
    with open(os.path.join(RESULTS, "pass_log.txt"), "w") as f:
        for name, log in pass_logs.items():
            f.write(f"### {name}\n{log}\n\n")
    write_markdown(results, args, cpus)
    print(open(os.path.join(RESULTS, "results.md")).read())


def write_markdown(results, args, cpus):
    by = collections.defaultdict(dict)
    for r in results:
        by[(r["cpu"], r["kernel"])][r["variant_id"]] = r
    L = [f"# Results (problem size {args.size})", ""]
    L.append("* **est. cycles** = sum over the kernel's basic blocks of "
             "(exact execution count, from a QEMU instruction trace) x "
             "(llvm-mca steady-state cycles for that block on the target "
             "CPU's scheduling model). Excludes cache misses - every load "
             "is modelled as an L1 hit.")
    L.append("* **speedup** is relative to `clang -O3` on the same CPU.")
    L.append("* **max rel. error** vs. a strictly in-order scalar "
             "reference, worst case over SVE vector lengths "
             "128/256/512/2048 bits.")
    L.append("* **hot loop** = vector ISA used by the block with the most "
             "estimated cycles.")
    L.append("")
    for cpu, vl, machine in cpus:
        L.append(f"## {machine} (`-mcpu={cpu}`, {vl}-bit SVE)")
        L.append("")
        for k in KERNELS:
            L.append(f"### {k}")
            L.append("")
            L.append("| variant | hot loop | dyn. instructions | est. cycles "
                     "| speedup | max rel. error | bit-exact |")
            L.append("|---|---|---:|---:|---:|---:|:---:|")
            rows = by[(cpu, k)]
            base = rows.get("clang_O3", {})
            for v in variants(cpu):
                r = rows.get(v["id"])
                if not r:
                    continue
                errs = [float(c.get("max_rel_err", "nan"))
                        for c in r["correctness"]]
                exact = all(c.get("bit_exact") == "1"
                            for c in r["correctness"])
                ok = all(c["ok"] for c in r["correctness"])
                verdict = ("yes" if exact else "no") + ("" if ok else " **FAIL**")
                if "est_cycles" in r:
                    sp = (base.get("est_cycles", 0) / r["est_cycles"]
                          if r["est_cycles"] else 0)
                    L.append(f"| {v['name']} | {vec_kind(r)} "
                             f"| {r['dyn_insns']:,} | {r['est_cycles']:,.0f} "
                             f"| **{sp:.2f}x** | {max(errs):.1e} | {verdict} |")
                else:
                    L.append(f"| {v['name']} | - | - | - | - "
                             f"| {max(errs):.1e} | {verdict} |")
            L.append("")
    with open(os.path.join(RESULTS, "results.md"), "w") as f:
        f.write("\n".join(L) + "\n")


if __name__ == "__main__":
    main()
