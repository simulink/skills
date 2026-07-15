# Phase 1: Model Inspection

First, determine the model to export. The user may provide `$model` or you may need to ask.

1. **Locate the model**: Find the `.slx` or `.mdl` file. If the user gave a name without extension, search for it.
   > **Built-in Examples**: If the user provides a built-in example name (e.g., `simscape/PermanentMagnetDCMotorExample`), you must run MATLAB to open and save a local copy before inspecting. For example, using the MATLAB MCP server's `eval_matlab` tool with the `code` parameter:
   > `openExample('simscape/PermanentMagnetDCMotorExample'); save_system(bdroot, fullfile(pwd, 'local_model.slx'))`
   > If the MATLAB MCP server is not available, use `matlab -batch "openExample('simscape/PermanentMagnetDCMotorExample'); save_system(bdroot, fullfile(pwd, 'local_model.slx'))"`.
   > Then use the absolute path to `local_model.slx` for the rest of the workflow.

2. **Inspect the model** by running MATLAB to extract key information.

**IMPORTANT RULES**: 
- **Absolute paths**: Always use absolute paths for the model path. If using MATLAB `-batch`, it may set `pwd=/tmp`.

Run the bundled inspection script using the MATLAB MCP server's `eval_matlab` tool with the following `code` parameter:
```matlab
addpath('<SKILL_DIR>/scripts');
inspect_model('<ABSOLUTE_PATH_TO_SLX>');
```
> **Note on `<SKILL_DIR>`**: Dynamically resolve the absolute path to this skill directory at runtime to locate the bundled scripts.
> If the MATLAB MCP server is not available, execute this via shell command:
> `matlab -batch "addpath('<SKILL_DIR>/scripts'); inspect_model('<ABSOLUTE_PATH_TO_SLX>')"`

3. **Present findings** to the user: number of I/O ports, solver type, parameters found, and any base workspace dependencies.
