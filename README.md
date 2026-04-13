# Simulink skills for agentic coding tools by Guy on Simulink

A collection of skills for AI coding agents by [Guy on Simulink](https://blogs.mathworks.com/simulink/).

The skills are designed to guide AI agents to interact with Simulink models programmatically via the [MATLAB MCP server](https://github.com/mathworks/matlab-mcp). These skills encode best practices and guard against common pitfalls so the agent produces correct MATLAB/Simulink code on the first try.

More specifically, they force the agent to generate code that uses what I consider modern best practices and that keeps the code short and simple.

**Disclaimer:** *This set of skills is not an official MathWorks product and might not be appropriate for all users and use cases. They are useful for me, for the kind of code and Simulink models I publish on [Guy on Simulink](https://blogs.mathworks.com/simulink/). As the disclaimer on the blog says: These postings are the author's and don't necessarily represent the opinions of MathWorks.*


## Skills

### `simulink-interactions`

Interact with a Simulink model that is already open in MATLAB — inspect blocks, change parameters, add and connect blocks, log signals, and create subsystems.

**Triggers on:** "change the gain", "color all Sum blocks", "find all integrators", "add a Scope here", or any reference to "this model / block / subsystem".

Key conventions enforced:
- Resolve context with `bdroot`, `gcs`, `gcb` before acting
- Use `Simulink.connectBlocks` instead of `add_line`
- Position blocks with bundled `setBlockPosition` / `setBlockDimensions` utilities — never raw `'Position'` vectors
- Log signals via port handles — never To Workspace blocks

### `simulink-simulation`

Run simulations the right way using the `Simulink.SimulationInput` / `SimulationOutput` API.

**Triggers on:** any request involving `sim()`, `SimulationInput`, `logsout`, `setExternalInput`, parameter sweeps, or `parsim`.

Key conventions enforced:
- Always drive simulations through `SimulationInput` — never bare `set_param` + `sim`
- Pass inputs via `Simulink.SimulationData.Dataset` with correctly named timeseries
- Discover logged signal names before accessing them
- Use `parsim` for batch / parallel runs

### `simulink-baseline-test`

Generate a MATLAB baseline (golden-reference) regression test for a Simulink model using `sltest.TestCase` and `verifySignalsMatch`.

**Triggers on:** "create a baseline test", "golden-reference test", or "regression test" for a Simulink model.

Key conventions enforced:
- Inherit from `sltest.TestCase`, not `matlab.unittest.TestCase`
- Simulate once, compare all signals in a single `verifySignalsMatch` call
- Use `RelTol` / `AbsTol` directly — no manual scaling
- Smart teardown with `bdIsLoaded` check
- Include a static `generateBaseline()` method for easy re-baselining

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

- **MATLAB** with **Simulink** (and **Simulink Test** for the baseline-test skill)
- The [MATLAB MCP server](https://github.com/mathworks/matlab-mcp) configured in your agentic coding tool environment
- An agentic coding tool: [Claude code](https://code.claude.com/docs/en/overview), [Sourcegraph Amp](https://ampcode.com), [GitHub® Copilot](https://github.com/features/copilot), [Cursor](https://www.cursor.com/), [OpenAI® Codex](https://openai.com/codex), [Gemini™ CLI](https://github.com/google-gemini/gemini-cli)

## Installation

### Option 1 — Project-level (recommended)

Copy the skill folders you need into your project's `.amp/skills/` directory:

```
.amp/skills/
├── simulink-interactions/
│   ├── SKILL.md
│   └── utils/
├── simulink-simulation/
│   └── SKILL.md
└── simulink-baseline-test/
    └── SKILL.md
```

### Option 2 — User-level (available in all projects)

Copy the skill folders into your global skills directory:

| OS | Path |
|---|---|
| Windows | `%USERPROFILE%\.amp\skills\` |
| macOS / Linux | `~/.amp/skills/` |

## Usage

Once installed, skills are activated automatically when your prompt matches their trigger description. You can also invoke them explicitly:

```
> Use the simulink-simulation skill to sweep the gain from 1 to 10 and plot the step response for each value.
```

```
> Use the simulink-baseline-test skill to create a regression test for this model.
```

### MathWorks Products (https://www.mathworks.com)

*   [MATLAB](https://www.mathworks.com/products/matlab.html)
*   [Simulink](https://www.mathworks.com/products/simulink.html)

### License

The license is available in the License.txt file in this GitHub repository.

### Community Support

[MATLAB Central](https://www.mathworks.com/matlabcentral)

Copyright 2026 The MathWorks, Inc.
