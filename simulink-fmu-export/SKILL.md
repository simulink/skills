---
name: export-fmu
description: Export a Simulink model to FMU (Functional Mock-Up Unit). Use this skill when the user asks to export a Simulink model to FMU, configure FMI versions, or needs help generating and validating an FMU file.
---

# Export Simulink Model to FMU

You are helping the user export a Simulink model to FMU format. Operate autonomously: extract as much configuration as possible from the user's initial request and execute the workflow without unnecessary interruptions. Only stop and ask questions if information necessary to complete the process (e.g., model name, mandatory export settings) is missing or ambiguous.

## Examples of Triggers
- "Export my ac_motor model to FMU."
- "Convert the Simulink model in this folder to an FMU file."
- "Generate an FMU from the vehicle dynamics model."

**Progress Updates**: Because you are operating autonomously, you must provide visibility to the user. Before starting each new phase, output a brief text announcement (e.g., "▶️ **Starting Phase 1: Model Inspection...**") so the user can follow along.

Follow this multi-phase workflow. Load the detailed instructions for each phase ONLY when you are ready to execute it.

1. **Phase 1: Model Inspection**
   Read `[references/phase1_inspection.md](references/phase1_inspection.md)` for instructions on locating and inspecting the model.
2. **Phase 2: Configuration**
   Read `[references/phase2_configuration.md](references/phase2_configuration.md)` for configuring FMI versions, tunable parameters, and other export options.
3. **Phase 3: FMU Generation**
   Read `[references/phase3_generation.md](references/phase3_generation.md)` for executing the build command and handling parameters.
4. **Phase 4: Error Analysis** (If the build fails)
   Read `[references/phase4_error_analysis.md](references/phase4_error_analysis.md)` to diagnose and fix common compilation errors.
5. **Phase 5: Post-Export Validation**
   Read `[references/phase5_validation.md](references/phase5_validation.md)` to verify the FMU structure and simulate the output.

After validation is complete, provide a final results summary to the user detailing the FMU file path, size, FMI version/type, exposed parameters, and simulation results.
