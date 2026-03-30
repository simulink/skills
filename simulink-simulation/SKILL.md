---
name: simulink-simulation
description: Use this skill whenever simulating a Simulink model, running the sim command, setting up SimulationInput objects, passing input signals via timeseries or datasets, configuring model or block parameters programmatically, or accessing logged output data from SimulationOutput. Trigger for any request involving sim(), Simulink.SimulationInput, Simulink.SimulationOutput, logsout, setExternalInput, or setModelParameter.
---

# Simulating Simulink Models with the sim Command

## Minimal working pattern

Always simulate using `Simulink.SimulationInput` and `Simulink.SimulationOutput`:

```matlab
in = Simulink.SimulationInput('MyModel');
in = in.setModelParameter('StopTime', '10');
out = sim(in);
```

Never use `set_param`, `load_system`, or `open_system` to drive simulation — the `SimulationInput` API replaces all of these.

## Setting parameters

Use `SimulationInput` methods to configure the simulation:

```matlab
% Model-level parameters (StopTime, SolverType, SimulationMode, etc.)
in = in.setModelParameter('StopTime', '10', 'SolverType', 'Fixed-step');

% Block parameters
in = in.setBlockParameter('MyModel/Gain', 'Gain', '5');

% MATLAB workspace variables used by the model
in = in.setVariable('Kp', 1.2);
```

## Input signals

Pass input signals through Inport blocks using a `Simulink.SimulationData.Dataset`. Each timeseries `Name` must match the corresponding Inport block's signal name, otherwise the signal won't be routed correctly.

```matlab
dt = 0.01; % sample time
N = 1000; % Number of points
t = dt*(0:N)';
u = sin(2*pi*t);

ts = timeseries(u, t);
ts.Name = 'mySignal';   % must match the Inport signal name in the model

ds = Simulink.SimulationData.Dataset;
ds{1} = ts;

in = in.setExternalInput(ds);
out = sim(in);
```

## Discovering logged signals

Before accessing logged data by name, discover what signals the model actually logs by running a simulation and inspecting `logsout`:

```matlab
in = Simulink.SimulationInput('MyModel');
out = sim(in);
disp('List of logged signals:');
disp(out.logsout.getElementNames);
```

This is especially useful when working with an unfamiliar model — the names returned here are exactly the names to use when calling `out.logsout.get(...)`.

## Accessing logged data

Logged signals are available through `out.logsout`. Access them directly by name — no intermediate variables needed:

```matlab
% Plot a logged signal
plot(out.logsout.get('signalName').Values)

% Get time and data separately
sig = out.logsout.get('signalName').Values;
plot(sig.Time, sig.Data)
```

Do not validate `out` with try-catch or `isfield` — `sim` either returns a valid `SimulationOutput` or throws an error. `Simulink.SimulationOutput` has no `isfield` method.

## Multiple simulations

When running many simulations, create an array of `Simulink.SimulationInput` objects using the `repmat` function instead of looping over `sim`:

```matlab
in = repmat(Simulink.SimulationInput('MyModel'),N,1);
for k = 1:N
    in(k) = Simulink.SimulationInput('MyModel');
    in(k) = in(k).setVariable('gain', gains(k));
end
out = sim(in);
```

## Parallel simulation (parsim)

To run multiple simulations, use `parsim` instead of looping over `sim`:

```matlab
for k = 1:N
    in(k) = Simulink.SimulationInput('MyModel');
    in(k) = in(k).setVariable('gain', gains(k));
end
out = parsim(in);
```
