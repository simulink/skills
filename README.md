# Simulink skills for agentic coding tools by Guy on Simulink

A collection of skills for AI coding agents by [Guy on Simulink].

Skills in this repository are designed to work with the [Simulink Agentic Toolkit]. Make sure you install the Simulink Agentic Toolkit before using skills from this repository. The skills in this repository provide additional functionalities for specialized workflows that are not included in the Simulink Agentic Toolkit.

**Disclaimer:** *This set of skills is not an official MathWorks product and might not be appropriate for all users and use cases. They are useful for me, for the kind of code and Simulink models I publish on [Guy on Simulink]. As the disclaimer on the blog says: These postings are the author's and don't necessarily represent the opinions of MathWorks.*


## Skills

### `simulink-interactions`

Interact with a Simulink model that is already open in MATLAB — inspect blocks, change parameters, add and connect blocks, log signals, and create subsystems.

**Triggers on:** "change the gain", "color all Sum blocks", "find all integrators", "add a Scope here", or any reference to "this model / block / subsystem".

Key conventions enforced:
- Resolve context with `bdroot`, `gcs`, `gcb` before acting
- Use `Simulink.connectBlocks` instead of `add_line`
- Position blocks with bundled `setBlockPosition` / `setBlockDimensions` utilities — never raw `'Position'` vectors
- Log signals via port handles — never To Workspace blocks

### `simulink-debug-commandline`

Debug Simulink simulation results at the engine method level using the command-line debugger (`sldebug`). Steps through individual block methods (Outputs, Update, Derivatives, InitializeConditions, Enable, Disable) to pinpoint exactly why a block produces an unexpected value at a specific time step.

**Triggers on:** "output is wrong at this time step", "block produces unexpected value", "state resets unexpectedly", "debug block execution", "what happens at t=X", "step through the simulation loop", "use sldebug", "probe block data", "trace block I/O", "debug block methods".

### Profiling Skills

#### `simulink-profile-initialization`

Profile and analyze the initialization (compile) phase of a Simulink model. Collects timing metadata, Performance Tracer data, and MATLAB Profiler results, then generates interactive HTML flamegraph reports highlighting user-actionable bottlenecks.

**Triggers on:** "profile model initialization", "why is my model slow to compile", or when existing profiling files (`out_after.mat`, `perfTracer.mat`, `profilerResults.mat`) are provided.

#### `simulink-profiler-analyzer`

Analyze Simulink Profiler data to find simulation-time bottlenecks, or compare two profiler sessions side-by-side to pinpoint performance regressions between releases or design changes.

**Triggers on:** "profile this model", "find what is slow", "compare profiler sessions", or when a `Simulink.profiler.Data` variable or MAT-file is provided.

#### `simulink-solver-profiler-analyzer`

Run the Simulink Solver Profiler and interpret the results — solver resets, exceptions, zero crossings, Jacobian updates, and algebraic loops — with prioritized recommendations and a standalone HTML report.

**Triggers on:** "run the solver profiler", "diagnose solver issues", or when solver profiler session data is provided.

## Prerequisites

- **MATLAB** with **Simulink**
- The [MATLAB MCP server](https://github.com/matlab/matlab-mcp-core-server) configured in your agentic coding tool environment
- An agentic coding tool: [Claude Code](https://code.claude.com/docs/en/overview), [Sourcegraph Amp](https://ampcode.com), [GitHub® Copilot](https://github.com/features/copilot), [Cursor](https://www.cursor.com/), [OpenAI® Codex](https://openai.com/codex), [Gemini™ CLI](https://github.com/google-gemini/gemini-cli)

## Installation

### Option 1 — Project-level (recommended)

Copy the skill folders you need into your project's skills directory. The location depends on your coding agent:

| Agent | Skills directory |
|---|---|
| Amp | `.amp/skills/` |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| Other agents | Check your agent's documentation |


### Option 2 — User-level (available in all projects)

Copy the skill folders into your global skills directory:

| Agent | Windows | macOS / Linux |
|---|---|---|
| Amp | `%USERPROFILE%\.amp\skills\` | `~/.amp/skills/` |
| Claude Code | `%USERPROFILE%\.claude\skills\` | `~/.claude/skills/` |
| Cursor | `%USERPROFILE%\.cursor\skills\` | `~/.cursor/skills/` |

## Usage

Once installed, skills are activated automatically when your prompt matches their trigger description. You can also invoke them explicitly:

```
> Use the simulink-interactions skill to color all Gain blocks red.
```

```
> Use the simulink-profiler-analyzer skill to find what is slow in this model.
```

### MathWorks Products (https://www.mathworks.com)

*   [MATLAB](https://www.mathworks.com/products/matlab.html)
*   [Simulink](https://www.mathworks.com/products/simulink.html)
*   [Simulink Agentic Toolkit]

### License

The license is available in the license.txt file in this GitHub repository.

### Community Support

[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2026 The MathWorks, Inc.

[Guy on Simulink]: https://blogs.mathworks.com/simulink/
[Simulink Agentic Toolkit]: https://github.com/matlab/simulink-agentic-toolkit
