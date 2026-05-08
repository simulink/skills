---
name: simulink-debug-commandline
description: Use when simulation results are wrong for specific blocks or specific time steps and you need to inspect exactly what happens inside the simulation engine at that moment. Trigger on "output is wrong at this time step", "block produces unexpected value", "state resets unexpectedly", "debug block execution", "what happens at t=X", "step through the simulation loop", "use sldebug", "probe block data", "trace block I/O", "debug block methods". This is the method-level debugger — not signal logging (big picture) or graphical breakpoints (set_param).
---

# Command-Line Simulink Debugger (`sldebug`)

Text-based debugger that steps through the Simulink simulation loop at the **engine method level** — you see individual block methods (Outputs, Update, Derivatives, InitializeConditions, Enable, Disable) rather than just signal values. For enabled/triggered subsystems, pay special attention to `Disable` and `Enable` methods — these can reset or reinitialize block states and are a common source of unexpected behavior.

- **Use sldebug** when you've localized unexpected behavior to a few blocks or time steps and need to understand *why* — which method caused a state change, what the I/O was at that moment, or why the solver chose a particular step size.
- **Don't use sldebug** for big-picture analysis. Use signal logging first to identify *which* blocks and *which* time range are problematic, then switch to sldebug to zoom in.
- **Decision rule**: Use `trace` for continuous observation, `break` when you need to pause and decide, `strace` only for solver behavior.

## Default Workflow (Trace + Step Top)

The preferred pattern uses **trace points** (auto-print block I/O on every method execution, without pausing) combined with `step top`. One `step top` shows the complete execution sequence for an entire time step in a single tool call — far more efficient than break → probe → continue loops.

1. **Identify suspect blocks and time range** — use `model_read` / `model_overview` + signal logging to find *which blocks* produce wrong output and *around which time step*.
2. **`sldebug('topModelName')`** — start the debugger in one `evaluate_matlab_code` call.
3. **`slist`** — find block IDs of suspect blocks. Note the model name prefix if inside a Model Reference.
4. **`trace (0)sysIdx:blkIdx`** for each suspect block — prints U/Y/DSTATE/CSTATE on every method execution. Multiple `trace` commands can be batched (newline-separated).
5. **`tbreak T`** if needed — skip ahead to the time range of interest.
6. **`step top`** — advance to next major time step. All traced blocks auto-print. **Note**: the first `step top` from `@0` executes all initialization methods (SetupRunTimeResources, InitializeConditions, Enable) before the first Outputs.Major — watch for unexpected state resets during init.
7. **Repeat `step top`** to observe evolution across time steps. Especially powerful for **For Iterator subsystems** — one `step top` shows all iterations.
8. **`stop`** when done.

Use breakpoints (`break` + `probe` → `step over` → `continue`) only when you need to conditionally examine data at a specific iteration or method before deciding what to do next. Use `break ... Outputs` or `break ... Update` to filter to a specific method — without a method name, `break` catches every method including init.

## Session Rules

`sldebug` is interactive and blocks the MATLAB command window. The session **persists across `evaluate_matlab_code` calls**.

- **Batch non-stepping commands** (`trace`, `break`, `untrace`, `clear`, `status`, `probe`) in a single call (newline-separated).
- **Stepping/execution commands** (`step top`, `step over`, `continue`, `stop`) should each be in their **own call**.

## Block Addressing

Blocks are identified by `(taskIdx)sysIdx:blkIdx` — e.g., `(0)0:1`, `(1)0:3`. Use `slist` to find IDs. Always include the parenthesized task index.

| Component | Meaning |
|---|---|
| `taskIdx` | 0 for continuous, 1+ for discrete rates |
| `sysIdx` | System index (0 = root) |
| `blkIdx` | Block index in the sorted execution list |

**Model References**: Prefix commands with the referenced model name — `break mRefChild (0)1:3`, `probe mRefChild (0)1:3`. Without the prefix, the debugger reports "system not found".

**Synthesized blocks**: `slist` may show engine-generated blocks (e.g., `OutportBufferForOut1`). These cannot be traced or probed but appear in the execution order. Include them when reporting `slist` results so the user understands what the engine inserted.

## Command Reference

### Core commands

| Goal | Command |
|---|---|
| Start debugger | `sldebug('modelName')` |
| Find block IDs | `slist` |
| Trace block I/O (auto-print) | `trace (0)sys:blk` / `untrace (0)sys:blk` |
| Probe block snapshot | `probe (0)sys:blk` |
| Show all states | `states` |
| Advance one major time step | `step top` |
| Step over current method | `step over` |
| Step into subsystem | `step` or `step in` |
| Step out of subsystem | `step out` |
| Break before method | `break (0)sys:blk [Method]` |
| Break after method | `bafter (0)sys:blk [Method]` |
| Break at time T (toggle) | `tbreak T` |
| Resume to next breakpoint | `continue` |
| Show breakpoints/settings | `status` |
| Remove breakpoint | `clear N` or `clear (0)sys:blk` |
| Current position in sim loop | `where` |
| End session | `stop` |

### Specialized breakpoints (all toggles — run again to disable)

| Command | Pauses when |
|---|---|
| `nanbreak` | Signal produces NaN or Inf |
| `zcbreak` | Zero-crossing event occurs |
| `xbreak` | State limits solver step size |
| `ebreak` | Solver encounters an error |
| `rbreak` | Solver requests a reset |

### Solver debugging (advanced)

Use the **`simulink-solver-profiler-analyzer`** skill first to identify problematic time ranges. Then use `strace 1` + `tbreak` to zoom in on *why* the solver behaves that way. Key solver trace prefixes: `TM` = major step, `Ts - Hs` = successful minor step, `Err - Ix` = normalized error (>1 = step fails, `Ix` identifies the limiting state — run `states` to map it). For zero-crossing analysis, use `zcbreak` + `zclist`.

## Gotchas

- **Do NOT call `sim()` while `sldebug` is active** — sldebug already runs the simulation; concurrent `sim()` will error.
- **Do NOT use bare `sysIdx:blkIdx`** — always include the task index: `(0)0:1`, not `0:1`.
- **Do NOT fall back to signal logging** — when this skill is requested, use the command-line debugger. Signal logging cannot reveal which block *method* caused a state change.
- **Do NOT use break → probe → continue as the primary pattern** — prefer `trace` + `step top`. Only use breakpoints when you need conditional pausing.
- **`tbreak` is a toggle** — run `tbreak T` again to disable it. Use `status` to verify active breakpoints.
- **Multi-rate models** — blocks in different rate groups have different task indices; verify with `slist`.
- **Do NOT use `emode`** — legacy command.

## See Also

- **simulink-debug-in-editor** — Graphical in-editor breakpoints via `set_param` on port handles. Use for conditional breakpoints on signal values (pause when output > X) with the Play button.
