import os
import lit.formats

config.name = "sve-vectorize-hint"
config.test_format = lit.formats.ShTest(execute_external=False)
config.suffixes = [".ll"]
config.test_source_root = os.path.dirname(__file__)

root = os.path.dirname(config.test_source_root)
plugin = os.path.join(root, "build", "libSveVectorizeHint.so")
opt = "opt-18"
filecheck = "FileCheck-18"

# `-load` registers the plugin's command-line options before parsing;
# `-load-pass-plugin` registers the pass with the new pass manager.
# loop-simplify mirrors what the -O3 pipeline guarantees before us.
config.substitutions.append(
    ("%opt_sve",
     f"{opt} -load {plugin} -load-pass-plugin {plugin} -sve-hint-quiet "
     f"-mtriple=aarch64-linux-gnu -passes=loop-simplify,sve-vectorize-hint "
     f"-S"))
config.substitutions.append(("FileCheck", filecheck))
