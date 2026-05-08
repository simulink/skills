function collectInitProfiling(mdl)
%collectInitProfiling Profile the initialization phase of a Simulink model.
%   collectInitProfiling(mdl) profiles the compile/init phase of the
%   specified model by simulating with StopTime=0. If mdl is not provided,
%   bdroot is used.
%
%   Produces four files in the current directory:
%     out_after.mat          - SimulationOutput with timing metadata
%     profilerResults.mat    - MATLAB Profiler results (variable p)
%     perfTracer.mat         - Simulink Performance Tracer raw data
%     modelCompileDiary.txt  - Command window diary
%
%   Also creates a timestamped .zip archive of all four files.

    if nargin < 1
        mdl = bdroot;
    end

    % Detect model references and their simulation modes
    [~, mdlRefs] = find_mdlrefs(mdl, 'ReturnTopModelAsLastElement', false);
    hasModelRefs = ~isempty(mdlRefs);
    modelInfo.hasModelRefs = hasModelRefs;
    modelInfo.modelRefRebuild = get_param(mdl, 'UpdateModelReferenceTargets');
    if hasModelRefs
        refModels = struct('blockPath', {}, 'modelName', {}, 'simMode', {});
        for k = 1:numel(mdlRefs)
            blkPath = mdlRefs{k};
            refModels(k).blockPath = blkPath;
            refModels(k).modelName = get_param(blkPath, 'ModelName');
            refModels(k).simMode = get_param(blkPath, 'SimulationMode');
        end
        modelInfo.refModels = refModels;
    end
    save modelRefInfo modelInfo

    PerfTools.Tracer.enable('All Simulink Compile', true);
    PerfTools.Tracer.clearRawData();
    profile on -historysize 50000000
    diary off
    if isfile('modelCompileDiary.txt')
        delete('modelCompileDiary.txt');
    end
    diary modelCompileDiary.txt
    ModelRefRebuild = get_param(mdl, 'UpdateModelReferenceTargets') %#ok<NOPRT>
    out = sim(mdl, 'StopTime', '0', 'CaptureErrors', 'on');
    diary off
    p = profile('info');
    save profilerResults p
    PerfTools.Tracer.saveToFile('perfTracer.mat')
    save out_after out
    PerfTools.Tracer.enable('All Simulink Compile', false);
    zip(['PerfData-' char(datetime("now", 'Format', "uuuuMMdd'T'HHmmss")) '.zip'], ...
        {'out_after.mat', 'perfTracer.mat', 'profilerResults.mat', 'modelCompileDiary.txt', 'modelRefInfo.mat'});
end
