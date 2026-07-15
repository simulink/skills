# Phase 5: Post-Export Validation

Once the FMU is generated successfully:

1. **Verify the FMU file** exists and has reasonable size:
```bash
ls -lh <output_dir>/<fmu_name>.fmu
unzip -l <output_dir>/<fmu_name>.fmu | head -30
```

2. **Check FMU structure** — a valid FMU contains:
   - `modelDescription.xml`
   - `binaries/linux64/` (FMI 2.0) or `binaries/x86_64-linux/` (FMI 3.0)
   - `binaries/win64/` (FMI 2.0) or `binaries/x86_64-windows/` (FMI 3.0)
   - `sources/` (if source code was included)

3. **Select validation approach**: Automatically validate using Option A (if a harness was generated) or Option B (if no harness exists), unless the user specified a different preference or asked to skip.

### Option A: Simulink Test Harness
If `CreateModelAfterGeneratingFMU` was enabled:
```matlab
cd('<output_dir>');
open_system('<model>_harness');
sim('<model>_harness');
```

### Option B: fmusim (Recommended)

fmusim is a standalone CLI tool from the Reference-FMUs project. **PyPI/pip is blocked on MathWorks internal network**, so use fmusim instead of FMPy.

**Download and setup** (one-time, Linux only):
```bash
bash <SKILL_DIR>/scripts/setup_fmusim.sh
```

**Run simulation**:
```bash
/tmp/fmusim-x86_64-linux/fmusim \
    --interface-type cs \
    --stop-time 10 \
    --output-file /tmp/fmu_output/results.csv \
    <path_to_fmu>
```

**Verify parameter tuning works** (change a parameter and confirm output changes):
```bash
/tmp/fmusim-x86_64-linux/fmusim \
    --interface-type cs \
    --stop-time 1 \
    --start-value <param_name> <new_value> \
    --output-file /tmp/fmu_output/results_modified.csv \
    <path_to_fmu>
```

If the model has input ports, create a CSV input file:
```csv
time,input1,input2
0.0,1.0,0.0
1.0,1.0,0.0
5.0,2.0,1.0
10.0,2.0,1.0
```
Then pass `--input-file /tmp/fmu_input.csv`.

### Option C: FMPy (Python)

**NOTE**: PyPI is typically blocked on internal networks (403 Forbidden). Only offer this if the user has external network access or a pre-installed FMPy.

```bash
python3 -m pip install fmpy --user
fmpy info <path_to_fmu>
fmpy simulate <path_to_fmu> --stop-time 10
```

### Option D: Skip Validation
User can skip if they plan to validate elsewhere.
