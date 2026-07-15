# Phase 2: Configuration

Check if the user provided configuration preferences in their request. If any required settings are missing, stop and ask the user to provide them:

### 1. Required Settings
- **FMI Version** (`FMIVersion`): `'2.0'` or `'3.0'`
- **FMU Type** (`FMUType`): `'CS'` (Co-Simulation) or `'ME'` (Model Exchange)

**Important Constraints**:
- **Solver compatibility**: Both CS and ME support fixed-step and variable-step models. ME does not embed a solver (the importing environment provides one). Cross-platform CS builds require fixed-step.
- **FMI 3.0 limitations**: No multi-tasking for ME, no non-inlined S-functions, no nesting CS inside ME, clock export only for CS + fixed-step.
- **CS + Variable-step constraints**: `EnableFMUState` and `SupportMultiInstance` are not available when using CS with a variable-step solver.

### 2. Tunable Parameters
Based on the variables found during Model Inspection, configure the `ExportedParameters` argument. If the user didn't specify their preference, stop and ask them to choose:
- **None**: Pass nothing (default).
- **All**: Include all numeric workspace/dictionary variables found during inspection. You (the agent) will format them into a cell array, e.g., `{'var1', 'var2'}`.
- **List**: Ask the user to provide a specific list of variable names.
- **Regex**: Ask the user for a regular expression. You will match it against the variables found in Phase 1 to construct the cell array.

### 3. Optional Settings (present as checklist)

| Option | Parameter Name | Values | Default | Notes |
|--------|---------------|--------|---------|-------|
| FMU Name | `FMUName` | any string | model name | Custom name for the .fmu file |
| Save Directory | `SaveDirectory` | path | `pwd` | Where to write the .fmu |
| Create Harness | `CreateModelAfterGeneratingFMU` | `'on'`/`'off'` | `'off'` | Auto-generate test harness model |
| Enable FMU State | `EnableFMUState` | `'on'`/`'off'` | `'on'` | Support get/set FMU state for rollback/restart. Disabled for CS + variable-step. |
| Multi-Instance | `SupportMultiInstance` | `'on'`/`'off'` | `'off'` | When `'off'`, the FMU can only be instantiated once per process. Set to `'on'` to allow multiple instances. Disabled for CS + variable-step. |
| Save Source Code | `SaveSourceCodeToFMU` | `'on'`/`'off'` | `'off'` | Package C source inside the FMU. **Warning**: Must be 'off' if the model uses a variable-step solver. |
| Source Code Format | `SourceCodeFormat` | `'readable'`/`'obfuscated'` | `'readable'` | Only applies when SaveSourceCodeToFMU is `'on'` |
| Exported Parameters | `ExportedParameters` | cell array | `{}` | Which tunable parameters to expose |
| Exported Parameter Names | `ExportedParameterNames` | cell array | `{}` | Custom FMI names for exported parameters |
| Exported Calculated Parameters | `ExportedCalculatedParameters` | cell array | `{''}` | Calculated params to expose |
| Exported Internals | `ExportedInternals` | cell array | `{}` | Signals/states to expose |
| Exported Internal Names | `ExportedInternalNames` | cell array | `{}` | Custom FMI names for internals |
| Exported Input Names | `ExportedInputNames` | cell array | `{}` | Custom FMI names for inputs |
| Exported Output Names | `ExportedOutputNames` | cell array | `{}` | Custom FMI names for outputs |
| Data Type Conversion | `DataTypeConversion` | `'on'`/`'off'` | `'off'` | Auto-convert unsupported types. FMI 2.0 only (FMI 3.0 natively supports all types). |
| Add Icon | `AddIcon` | `'snapshot'`/`'off'`/path | `'snapshot'` | FMU icon image |
| Generate 32-bit DLL | `Generate32BitDLL` | `'on'`/`'off'` | `'off'` | Include 32-bit Windows binary |
| Embedded Target | `EmbeddedTarget` | `'on'`/`'off'` | `'off'` | Use Embedded Coder target (requires Embedded Coder license) |
| Constant Periodic Clock | `ConstantPeriodicClock` | `'on'`/`'off'` | `'off'` | FMI 3.0 clock export (CS + fixed-step only) |
| Include Time Variable | `IncludeTimeAsIndependentVariable` | `'on'`/`'off'` | `'on'` | Expose time as independent variable |
| Password Protection | `EnablePassword` | `'on'`/`'off'` | `'off'` | Password-protect the FMU |
| Cross-platform Linux (WSL) | `GenerateLinuxBinaryWithWSL` | `'on'`/`'off'` | `'off'` | Generate Linux binary on Windows via WSL |
| Build Config File | `FMUBuildConfigFile` | file path | `''` | Load export settings from a JSON config file |
| Save Build Config | `SaveCurrentFMUBuildConfig` | `'on'`/`'off'` | `'off'` | Save current settings to a JSON config file for reuse |
| Export with Project | `ExportedContent` | `'project'`/`'off'` | `'off'` | Export as MATLAB project |
| Custom Row-Major Layout | `CustomRowMajorLayout` | `'on'`/`'off'` | `'off'` | Use row-major array layout |