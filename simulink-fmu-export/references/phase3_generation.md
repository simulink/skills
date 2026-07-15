# Phase 3: FMU Generation

**IMPORTANT pre-export steps**:
1. Delete stale code generation cache: `rm -r /tmp/slprj 2>/dev/null` — a `/tmp/slprj` from a different MATLAB release causes `slprjVerIncompatibleCmdLine` errors.
2. If the model references base workspace variables, construct an evaluation string (e.g. `'ks=1; kt=1;'`) to pass to the helper script. The model won't compile without them.

**Important Notes for Generation**:
- **Parameter types**: `exportToFMU` options use char values (`'on'`/`'off'`), not logical `true`/`false`.
- **Large models**: Export can take 5-20 minutes depending on model complexity and code generation.
- **License requirements**: Requires Simulink FMU Builder after R2026a and Simulink Compiler before 2025b. Simulink Coder needed if `SaveSourceCodeToFMU` is `'on'`.

**Correct parameter names** (common mistakes to avoid):
- Source code: `'SaveSourceCodeToFMU', 'on'` (NOT `'SaveSourceCode', true`)
- Harness: `'CreateModelAfterGeneratingFMU', 'on'`
- Multi-instance: `'SupportMultiInstance', 'on'` (NOT `'MultiInstance'`)
- FMU state: `'EnableFMUState', 'on'` (NOT `'canGetAndSetFMUState'`)

Run the bundled export script via:
```bash
rm -r /tmp/slprj 2>/dev/null; mw matlab -batch "addpath('<SKILL_DIR>/scripts'); export_fmu('<ABSOLUTE_PATH_TO_SLX>', '/tmp/fmu_output', 'ks=1; kt=1;', 'FMIVersion', '2.0', 'FMUType', 'CS', 'SaveSourceCodeToFMU', 'on')"
```

This can take 1-5 minutes. Run it and monitor output.

### Using a Build Config File

Instead of specifying all options inline, users can load settings from a previously saved JSON config (`FMUBuildConfigFile`), or save the current setup (`SaveCurrentFMUBuildConfig`):
```bash
mw matlab -batch "addpath('<SKILL_DIR>/scripts'); export_fmu('<ABSOLUTE_PATH_TO_SLX>', '/tmp/fmu_output', '', 'FMUBuildConfigFile', '/path/to/config.json')"
```