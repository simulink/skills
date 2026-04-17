---
name: simulink-interactions
description: Resolve references to the currently open or selected Simulink context ("this model", "this subsystem", "this block", "selected blocks") and find blocks in an open model. Use whenever the user refers to "this model", "this block", "this subsystem", "selected blocks", or asks to find specific blocks in an already-open model. After resolving context, hand off to the appropriate Simulink skill for edits, simulation, or testing.
metadata:
  version: "1.0"
---

# Simulink Open Model Context Resolution

Resolve what the user is referring to in an already-open Simulink session, then route to the right skill.

## When to Use

- User says "this model", "this block", "this subsystem", "selected blocks"
- User asks to find or locate blocks in the currently open model
- User refers to a model without specifying a file path to open

## When NOT to Use

- Adding, connecting, deleting, or configuring blocks → use `building-simulink-models`
- Running simulations, parameter sweeps, accessing `logsout` → use `simulating-simulink-models`
- Writing pass/fail behavioral tests → use `testing-simulink-models`
- Organizing variables and data dictionaries → use `simulink-data-management`

## Step 1: Resolve the Target

Use `mcp__simulink__evaluate_matlab_code` to resolve references:

| User says | MATLAB expression |
|---|---|
| "this model" | `bdroot(gcs)` |
| "this system" / "this subsystem" | `gcs` |
| "this block" | `gcb` |
| "selected blocks" (plural) | see snippet below |
| "all [Type] blocks in this subsystem" | see snippet below |
| "all [Type] blocks in the model" | see snippet below |

**Always verify the result is non-empty.** If `gcb` or `gcs` returns an empty string, tell the user no block or subsystem is currently selected and ask them to select one or provide a path.

### Selected blocks (plural)

```matlab
opts = Simulink.FindOptions;
opts.SearchDepth = 1;
blks = getfullname(Simulink.findBlocks(gcs, 'Selected', 'on', opts));
if isempty(blks)
    disp('No blocks are currently selected.');
else
    disp(blks)
end
```

### All blocks of a specific type in the current subsystem

```matlab
opts = Simulink.FindOptions;
opts.SearchDepth = 1;
BlockType = 'Gain'; % replace with actual type
blks = getfullname(Simulink.findBlocksOfType(gcs, BlockType, opts));
```

### All blocks of a specific type in the entire model

```matlab
BlockType = 'Gain'; % replace with actual type
blks = getfullname(Simulink.findBlocksOfType(bdroot, BlockType));
```

## Step 2: Hand Off

Once you have the resolved block path(s) or model name, use it as input to the appropriate skill:

| User intent | Hand off to |
|---|---|
| Inspect model structure or topology | `model_read` / `model_overview` |
| Query parameter values | `model_query_params` |
| Resolve variable-backed values | `model_resolve_params` |
| Edit structure or parameters | `building-simulink-models` (via `model_edit`) |
| Run simulation or access results | `simulating-simulink-models` |
| Write or run pass/fail tests | `testing-simulink-models` |
| Organize variables or dictionaries | `simulink-data-management` |
