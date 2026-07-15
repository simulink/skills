function inspect_model(mdlPath)
    % Use ABSOLUTE path — MATLAB -batch pwd is /tmp, not sandbox/matlab
    load_system(mdlPath);
    [~, mdl, ~] = fileparts(mdlPath);

    % Port info (do NOT call CompiledPortDataTypes — model is not compiled yet)
    inports = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'Inport');
    outports = find_system(mdl, 'SearchDepth', 1, 'BlockType', 'Outport');
    fprintf('Input ports (%d):\n', numel(inports));
    for i = 1:numel(inports)
        fprintf('  %s\n', get_param(inports{i}, 'Name'));
    end
    fprintf('Output ports (%d):\n', numel(outports));
    for i = 1:numel(outports)
        fprintf('  %s\n', get_param(outports{i}, 'Name'));
    end

    % Solver info
    solver = get_param(mdl, 'Solver');
    solverType = get_param(mdl, 'SolverType');
    fprintf('Solver: %s (%s)\n', solver, solverType);
    try
        stepSize = get_param(mdl, 'FixedStep');
        fprintf('Fixed step size: %s\n', stepSize);
    catch
    end
    fprintf('Stop time: %s\n', get_param(mdl, 'StopTime'));

    % Model workspace variables
    mdlWks = get_param(mdl, 'ModelWorkspace');
    varList = whos(mdlWks);
    if ~isempty(varList)
        fprintf('Model workspace variables (%d):\n', numel(varList));
        for i = 1:numel(varList)
            try
                val = evalin(mdlWks, varList(i).name);
                if isnumeric(val) && isscalar(val)
                    fprintf('  %s = %g (%s)\n', varList(i).name, val, varList(i).class);
                else
                    fprintf('  %s (%s, %s)\n', varList(i).name, varList(i).class, mat2str(varList(i).size));
                end
            catch
                fprintf('  %s (%s)\n', varList(i).name, varList(i).class);
            end
        end
    end

    % All referenced variables — categorized by workspace source
    allVars = Simulink.findVars(mdl);
    baseVars = {};
    slddVars = {};
    for i = 1:numel(allVars)
        switch allVars(i).WorkspaceType
            case 'base'
                baseVars{end+1} = allVars(i).Name; %#ok<AGROW>
            case 'data dictionary'
                slddVars{end+1} = allVars(i).Name; %#ok<AGROW>
        end
    end
    if ~isempty(baseVars)
        fprintf('Base workspace variables referenced (%d):\n', numel(baseVars));
        for i = 1:numel(baseVars)
            fprintf('  %s\n', baseVars{i});
        end
        fprintf('  WARNING: These must be defined before export (assignin or script).\n');
    end
    if ~isempty(slddVars)
        fprintf('Data dictionary variables referenced (%d):\n', numel(slddVars));
        ddPath = get_param(mdl, 'DataDictionary');
        fprintf('  Dictionary: %s\n', ddPath);
        for i = 1:numel(slddVars)
            fprintf('  %s\n', slddVars{i});
        end
        fprintf('  NOTE: SLDD must be accessible at export time. No action needed if path is valid.\n');
    end

    close_system(mdl, 0);
end
