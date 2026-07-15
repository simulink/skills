# Phase 4: Error Analysis

If the export fails, analyze the error output:

### Common Errors and Fixes
| Error Pattern | Cause | Fix |
|---------------|-------|-----|
| `CrossPlatformNotSupportedForVSS` | Cross-platform CS build with variable-step | Change solver to fixed-step, or disable cross-platform |
| `slprjVerIncompatibleCmdLine` | Stale `/tmp/slprj` from different release | `rm -r /tmp/slprj` and retry |
| `Unsupported block` | Block not supported for code generation | Replace or remove the block |
| `Code generation not supported` | Model uses interpreted-only blocks | Check block compatibility |
| `Data type not supported` | FMI 2.0 type mismatch | Enable `DataTypeConversion` option |
| `FMU3DataConversionError` | DataTypeConversion used with FMI 3.0 | Remove DataTypeConversion (not needed for FMI 3.0) |
| `License checkout failed` | Missing Simulink Coder license | Check license availability |
| `UnableToConvert` on a parameter | Wrong value type (logical instead of char) | Use `'on'`/`'off'` strings, not `true`/`false` |
| `Undefined variable` | Base workspace var not defined | Include assignment in `baseVarsEvalStr` |
| `NonInlinedSFcnsNotSupported` | Non-inlined S-functions in model | Inline the S-function or replace with supported block |

Present the error clearly and suggest fixes. If fixable programmatically (e.g., solver change), offer to apply the fix and retry.
