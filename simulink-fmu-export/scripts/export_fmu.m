function export_fmu(mdlPath, outDir, baseVarsEvalStr, varargin)
    % export_fmu(mdlPath, outDir, baseVarsEvalStr, ...)
    % mdlPath: Absolute path to the .slx or .mdl file
    % outDir: Directory to save the FMU
    % baseVarsEvalStr: A string of MATLAB code to evaluate in the base workspace before loading the model (e.g., 'ks=1; kt=1;')
    % varargin: Name-value pairs for exportToFMU
    
    if ~isempty(baseVarsEvalStr)
        evalin('base', baseVarsEvalStr);
    end

    load_system(mdlPath);
    [~, mdl, ~] = fileparts(mdlPath);
    
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % Make sure we pass the SaveDirectory
    args = [{'SaveDirectory', outDir}, varargin];
    
    try
        exportToFMU(mdl, args{:});
        fprintf('\nFMU exported successfully to: %s\n', fullfile(outDir, [mdl '.fmu']));
    catch ME
        fprintf('\nError during exportToFMU:\n%s\n', getReport(ME));
    end
    
    close_system(mdl, 0);
end
