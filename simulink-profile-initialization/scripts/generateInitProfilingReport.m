function generateInitProfilingReport(dataDir, outFile)
%generateInitProfilingReport Generate a combined HTML profiling report with flamegraph.
%   generateInitProfilingReport() uses files in the current directory.
%   generateInitProfilingReport(dataDir) uses files in the specified directory.
%   generateInitProfilingReport(dataDir, outFile) saves to the specified path.
%
%   Required files in dataDir:
%     out_after.mat, perfTracer.mat, profilerResults.mat, modelCompileDiary.txt

    if nargin < 1
        dataDir = pwd;
    end

    % --- 1. Timing overview (out_after.mat) ---
    S = load(fullfile(dataDir, 'out_after.mat'), 'out');
    ti = S.out.SimulationMetadata.TimingInfo;
    timing.init   = ti.InitializationElapsedWallTime;
    timing.exec   = ti.ExecutionElapsedWallTime;
    timing.term   = ti.TerminationElapsedWallTime;
    timing.total  = ti.TotalElapsedWallTime;
    timing.tstart = ti.WallClockTimestampStart;
    timing.tstop  = ti.WallClockTimestampStop;
    modelName = S.out.SimulationMetadata.ModelInfo.ModelName;
    errorMsg = S.out.ErrorMessage;

    % --- 2. Performance Tracer phases + flamegraph JSON ---
    [phases, flamegraphJson, perfTotalWall] = parsePerfTracerData(fullfile(dataDir, 'perfTracer.mat'));

    % --- 3. Profiler results (table + user-code flamegraph) ---
    [userFuncs, shipFuncs, userTotal, shipTotal] = parseProfilerData(fullfile(dataDir, 'profilerResults.mat'), 20);
    profilerFlamegraphJson = buildProfilerFlamegraph(fullfile(dataDir, 'profilerResults.mat'));

    % --- 4. ModelRefRebuild setting + model reference detection ---
    [mrrVal, mrrStatus, hasModelRefs] = parseModelRefInfo(dataDir);

    % --- Build HTML ---
    skillDir = fileparts(mfilename('fullpath'));
    templateFile = fullfile(skillDir, '..', 'reference', 'init_profiling_template.html');
    html = fileread(templateFile);

    % Findings
    findingsHtml = buildFindingsSection(timing, phases, perfTotalWall, userFuncs, userTotal, shipTotal, mrrVal, mrrStatus, hasModelRefs);
    html = strrep(html, '{{FINDINGS_SECTION}}', findingsHtml);

    % Model info
    modelInfoHtml = buildModelInfoRows(timing, mrrVal, mrrStatus, hasModelRefs, userTotal, shipTotal);
    html = strrep(html, '{{MODEL_INFO_ROWS}}', modelInfoHtml);

    % Phase table
    phaseTableHtml = buildPhaseTable(phases, perfTotalWall);
    html = strrep(html, '{{PHASE_TABLE_ROWS}}', phaseTableHtml);

    % User profiler table
    userTableHtml = buildProfilerTable(userFuncs);
    html = strrep(html, '{{USER_PROFILER_ROWS}}', userTableHtml);
    html = strrep(html, '{{USER_TOTAL}}', sprintf('%.3f', userTotal));
    html = strrep(html, '{{USER_PCT}}', sprintf('%.1f', userTotal/(userTotal+shipTotal)*100));

    % Shipping profiler table
    shipTableHtml = buildProfilerTable(shipFuncs);
    html = strrep(html, '{{SHIP_PROFILER_ROWS}}', shipTableHtml);

    % Flamegraph data (compile phases)
    html = strrep(html, '{{FLAMEGRAPH_DATA}}', flamegraphJson);
    html = strrep(html, '{{TOTAL_TIME}}', sprintf('%.3f', perfTotalWall));

    % Flamegraph data (profiler user code)
    html = strrep(html, '{{PROFILER_FLAMEGRAPH_DATA}}', profilerFlamegraphJson);

    % Section severity badges (based on absolute time thresholds)
    maxPhaseDur = max(cellfun(@(p) p.duration, phases));
    if maxPhaseDur >= 5
        html = strrep(html, '{{PHASE_BADGE}}', '<span class="badge badge-red">Critical</span>');
    else
        html = strrep(html, '{{PHASE_BADGE}}', '<span class="badge badge-green">OK</span>');
    end
    if userTotal >= 5
        html = strrep(html, '{{USER_BADGE}}', '<span class="badge badge-red">Critical</span>');
    elseif userTotal >= 1
        html = strrep(html, '{{USER_BADGE}}', '<span class="badge badge-yellow">Warning</span>');
    else
        html = strrep(html, '{{USER_BADGE}}', '<span class="badge badge-green">OK</span>');
    end
    if shipTotal >= 30
        html = strrep(html, '{{SHIP_BADGE}}', '<span class="badge badge-yellow">Warning</span>');
    else
        html = strrep(html, '{{SHIP_BADGE}}', '<span class="badge badge-green">OK</span>');
    end

    % Date, model name, and error section
    html = strrep(html, '{{DATE}}', char(datetime("now", 'Format', 'yyyy-MM-dd HH:mm:ss')));
    html = strrep(html, '{{MODEL_NAME}}', modelName);
    if ~isempty(errorMsg)
        errorMsg = regexprep(errorMsg, '<a[^>]*>', '');
        errorMsg = strrep(errorMsg, '</a>', '');
        errorHtml = sprintf([ ...
            '<div class="card" style="border-left:4px solid var(--red); background:var(--red-bg); margin-bottom:1.5rem;">\n' ...
            '<h3 style="color:var(--red); margin-bottom:0.5rem;">Simulation Error</h3>\n' ...
            '<p>The simulation encountered an error during execution. Profiling data may be incomplete.</p>\n' ...
            '<pre style="background:#fff; border:1px solid var(--border); border-radius:4px; padding:0.75rem; margin-top:0.5rem; white-space:pre-wrap; font-size:0.85rem;">%s</pre>\n' ...
            '</div>'], htmlEscape(errorMsg));
    else
        errorHtml = '';
    end
    html = strrep(html, '{{ERROR_SECTION}}', errorHtml);

    % ModelRefRebuild section
    if hasModelRefs
        mrrHtml = buildMrrSection(mrrVal, mrrStatus);
    else
        mrrHtml = '';
    end
    html = strrep(html, '{{MRR_SECTION}}', mrrHtml);

    % Save
    if nargin < 2
        outFile = fullfile(pwd, 'InitProfiling_Report.html');
    end
    fid = fopen(outFile, 'w', 'n', 'UTF-8');
    fwrite(fid, html, 'char');
    fclose(fid);
    fprintf('Report saved to: %s\n', outFile);
end

%% --- Model reference info parser ---
function [val, status, hasModelRefs] = parseModelRefInfo(dataDir)
    matFile = fullfile(dataDir, 'modelRefInfo.mat');
    if isfile(matFile)
        S = load(matFile, 'modelInfo');
        hasModelRefs = S.modelInfo.hasModelRefs;
        if isfield(S.modelInfo, 'modelRefRebuild')
            val = S.modelInfo.modelRefRebuild;
        else
            val = '(unknown)';
        end
    else
        % Old data without modelRefInfo.mat — assume true for safety
        hasModelRefs = true;
        val = '(unknown)';
    end

    if strcmp(val, 'IfOutOfDate')
        status = 'ok';
    elseif strcmp(val, 'AssumeUpToDate')
        status = 'info';
    elseif strcmp(val, '(unknown)')
        status = 'warning';
    else
        status = 'warning';
    end
end

%% --- HTML builders ---
function s = buildModelInfoRows(timing, mrrVal, mrrStatus, hasModelRefs, userTotal, shipTotal)
    grandTotal = userTotal + shipTotal;
    if grandTotal > 0
        userPct = userTotal / grandTotal * 100;
        shipPct = shipTotal / grandTotal * 100;
    else
        userPct = 0;
        shipPct = 0;
    end
    s = sprintf([ ...
        '<tr><td>Profiling Date</td><td>%s → %s</td></tr>\n' ...
        '<tr><td>Total Wall Time</td><td>%.2f s</td></tr>\n' ...
        '<tr><td>Initialization</td><td>%.2f s (%.1f%%)</td></tr>\n' ...
        '<tr><td>Execution</td><td>%.2f s (%.1f%%)</td></tr>\n' ...
        '<tr><td>Termination</td><td>%.2f s (%.1f%%)</td></tr>\n' ...
        '<tr><td>MATLAB Code: User</td><td>%.3f s (%.1f%%)</td></tr>\n' ...
        '<tr><td>MATLAB Code: MathWorks</td><td>%.3f s (%.1f%%)</td></tr>\n'], ...
        timing.tstart, timing.tstop, ...
        timing.total, ...
        timing.init, timing.init/timing.total*100, ...
        timing.exec, timing.exec/timing.total*100, ...
        timing.term, timing.term/timing.total*100, ...
        userTotal, userPct, ...
        shipTotal, shipPct);
    if hasModelRefs
        switch mrrStatus
            case 'ok'
                mrrBadge = '<span class="badge badge-green">OK</span>';
            case 'info'
                mrrBadge = '<span class="badge badge-blue">Info</span>';
            otherwise
                mrrBadge = '<span class="badge badge-red">Warning</span>';
        end
        s = [s, sprintf('<tr><td>ModelRefRebuild</td><td>%s <code>%s</code></td></tr>\n', mrrBadge, mrrVal)];
    end
end

function s = buildPhaseTable(phases, totalWall)
    % Sort phases by duration descending
    durations = cellfun(@(p) p.duration, phases);
    [~, order] = sort(durations, 'descend');
    s = '';
    for k = 1:numel(order)
        p = phases{order(k)};
        pct = p.duration / totalWall * 100;
        if pct < 0.5, continue; end  % skip tiny phases
        s = [s, sprintf('<tr><td>%s</td><td class="num">%.3f</td><td class="num">%.1f%%</td></tr>\n', ...
            htmlEscape(p.phase), p.duration, pct)]; %#ok<AGROW>
    end
end

function s = buildProfilerTable(funcs)
    s = '';
    for k = 1:numel(funcs)
        f = funcs(k);
        if ~isempty(f.file)
            fileLink = sprintf('<a href="matlab:edit(''%s'')"><code>%s</code></a>', ...
                strrep(f.file, '''', ''''''), htmlEscape(f.file));
        else
            fileLink = '<code>(unknown)</code>';
        end
        s = [s, sprintf('<tr><td class="num">%d</td><td><strong>%s</strong></td><td class="num">%.3f</td><td class="num">%.3f</td><td class="num">%d</td><td>%s</td></tr>\n', ...
            f.rank, htmlEscape(f.name), f.selfTime, f.totalTime, f.numCalls, fileLink)]; %#ok<AGROW>
    end
end

function s = buildMrrSection(val, status)
    switch status
        case 'ok'
            heading = '<h2><span class="badge badge-green">OK</span> ModelRefRebuild Setting</h2>';
            body = '<div class="card" style="border-left:4px solid var(--green);"><p><strong>IfOutOfDate</strong> — This is the recommended setting. Only rebuilds when dependencies change.</p></div>';
        case 'info'
            heading = '<h2><span class="badge badge-blue">Info</span> ModelRefRebuild Setting</h2>';
            body = '<div class="card" style="border-left:4px solid var(--blue);"><p><strong>AssumeUpToDate</strong> — Skips all rebuild checks. Fast, but risks using stale targets. Use only when certain no dependencies have changed.</p></div>';
        otherwise
            heading = '<h2><span class="badge badge-yellow">Warning</span> ModelRefRebuild Setting</h2>';
            body = sprintf([ ...
                '<div class="card" style="border-left:4px solid var(--red);">' ...
                '<p><strong>%s</strong> — This may cause unnecessary rebuilds and slow initialization.</p>' ...
                '<p><strong>Recommendation:</strong> Change to <code>IfOutOfDate</code>:</p>' ...
                '<p><code>set_param(mdl, ''UpdateModelReferenceTargets'', ''IfOutOfDate'')</code></p>' ...
                '<p>UI: Model Settings → Model Referencing → Rebuild → "If changes in known dependencies detected"</p>' ...
                '</div>'], htmlEscape(val));
    end
    s = [heading, newline, body];
end

function s = buildFindingsSection(timing, phases, perfTotalWall, userFuncs, userTotal, shipTotal, mrrVal, mrrStatus, hasModelRefs)
    items = {};
    grandTotal = userTotal + shipTotal;

    % 1. Initialization dominance
    initPct = timing.init / timing.total * 100;
    if initPct > 90
        items{end+1} = sprintf('<span class="badge badge-blue">Info</span> Initialization accounts for %.0f%% of total wall time &mdash; this is expected for a StopTime=0 profiling run.', initPct);
    end

    % 2. Top compile phases (>5% of total, but only flag if absolute time is significant)
    durations = cellfun(@(p) p.duration, phases);
    [~, order] = sort(durations, 'descend');
    phaseCount = 0;
    for k = 1:numel(order)
        p = phases{order(k)};
        pct = p.duration / perfTotalWall * 100;
        if pct >= 5 && p.duration >= 5
            phaseCount = phaseCount + 1;
            if phaseCount == 1
                items{end+1} = sprintf('<span class="badge badge-red">Critical</span> Phase &lsquo;%s&rsquo; is the largest compile phase at %.1fs (%.0f%% of total).', htmlEscape(p.phase), p.duration, pct); %#ok<AGROW>
            else
                items{end+1} = sprintf('<span class="badge badge-yellow">Warning</span> Phase &lsquo;%s&rsquo; consumes %.1fs (%.0f%% of total).', htmlEscape(p.phase), p.duration, pct); %#ok<AGROW>
            end
            if phaseCount >= 3, break; end
        end
    end

    % 3. User code hot spots (only flag if user code time is significant)
    if userTotal > 5.0 && ~isempty(userFuncs)
        nShow = min(3, numel(userFuncs));
        for k = 1:nShow
            f = userFuncs(k);
            if f.selfTime >= 1.0
                items{end+1} = sprintf('<span class="badge badge-yellow">Warning</span> User callback &lsquo;%s&rsquo; consumes %.1fs of self-time (%d calls). Consider optimizing or caching results.', htmlEscape(f.name), f.selfTime, f.numCalls); %#ok<AGROW>
            end
        end
    end

    % 4. User vs shipping split (only flag if absolute time is significant)
    if grandTotal > 0
        userPct = userTotal / grandTotal * 100;
        if userPct > 30 && userTotal > 5.0
            items{end+1} = sprintf('<span class="badge badge-red">Critical</span> User code accounts for %.0f%% of profiled self-time &mdash; significant optimization potential exists in user callbacks and scripts.', userPct);
        elseif userPct < 10
            items{end+1} = sprintf('<span class="badge badge-blue">Info</span> User code accounts for only %.0f%% of self-time &mdash; most time is spent in MathWorks shipping code.', userPct);
        end
    end

    % 5. ModelRefRebuild warning
    if hasModelRefs && strcmp(mrrStatus, 'warning')
        items{end+1} = sprintf('<span class="badge badge-yellow">Warning</span> ModelRefRebuild is set to &lsquo;%s&rsquo; which may cause unnecessary rebuilds. Change to <code>IfOutOfDate</code>.', htmlEscape(mrrVal));
    end

    % 6. All green — no significant issues found
    hasIssues = any(cellfun(@(x) contains(x, 'badge-red') || contains(x, 'badge-yellow'), items));
    if ~hasIssues
        items{end+1} = sprintf('<span class="badge badge-green">OK</span> Initialization completed in %.1fs with no significant bottlenecks detected.', timing.init);
    end

    % Build HTML
    if isempty(items)
        s = '';
    else
        liItems = '';
        for k = 1:numel(items)
            liItems = [liItems, sprintf('    <li style="margin-bottom:0.6rem;">%s</li>\n', items{k})]; %#ok<AGROW>
        end
        s = sprintf([ ...
            '<h2>Findings &amp; Recommendations</h2>\n' ...
            '<div class="card">\n' ...
            '  <ol style="margin:0.5rem 0 0.5rem 1.5rem;">\n' ...
            '%s' ...
            '  </ol>\n' ...
            '</div>\n'], liItems);
    end
end

function t = htmlEscape(str)
    t = strrep(str, '&', '&amp;');
    t = strrep(t, '<', '&lt;');
    t = strrep(t, '>', '&gt;');
    t = strrep(t, '"', '&quot;');
end

%% --- Profiler Flamegraph (user code only) ---
function json = buildProfilerFlamegraph(matFile)
    S = load(matFile, 'p');
    ft = S.p.FunctionTable;
    mr = matlabroot;
    N = length(ft);

    % Classify shipping vs user (treat profiling harness as shipping)
    isShipping = false(N, 1);
    for i = 1:N
        isHarness = strcmp(ft(i).FunctionName, 'collectInitProfiling');
        isShipping(i) = isHarness || startsWith(ft(i).FileName, mr, 'IgnoreCase', true) || isempty(ft(i).FileName);
    end

    % Find root: entry with no parents
    rootIdx = 1;
    for i = 1:N
        if isempty(ft(i).Parents)
            rootIdx = i;
            break;
        end
    end

    % Build tree recursively, collapsing shipping nodes
    visiting = false(N, 1);
    tree = buildUserTree(ft, rootIdx, ft(rootIdx).TotalTime, isShipping, visiting);

    % Assign sequential start positions for flamegraph layout
    tree = assignStarts(tree, 0);

    json = node2json(tree);
end

function node = buildUserTree(ft, idx, timeFromParent, isShipping, visiting)
    % Prevent infinite recursion on cycles
    if visiting(idx)
        node = struct('name', ft(idx).FunctionName, 'duration', timeFromParent, 'start', 0, 'children', {{}});
        return;
    end
    visiting(idx) = true;

    children = {};
    childTimeSum = 0;
    entry = ft(idx);

    if ~isempty(entry.Children)
        % Sort children by descending time for better flamegraph layout
        [~, ord] = sort([entry.Children.TotalTime], 'descend');
        for k = 1:length(ord)
            c = entry.Children(ord(k));
            childIdx = c.Index;
            childTime = c.TotalTime;
            if childTime < 0.001
                continue;
            end

            if isShipping(childIdx)
                % Collapse shipping node: promote its user-code descendants
                promoted = promoteUserChildren(ft, childIdx, childTime, isShipping, visiting);
                for p = 1:numel(promoted)
                    children{end+1} = promoted{p}; %#ok<AGROW>
                    childTimeSum = childTimeSum + promoted{p}.duration;
                end
            else
                childNode = buildUserTree(ft, childIdx, childTime, isShipping, visiting);
                children{end+1} = childNode; %#ok<AGROW>
                childTimeSum = childTimeSum + childTime;
            end
        end
    end

    % Cap child time to parent time
    if childTimeSum > timeFromParent
        childTimeSum = timeFromParent;
    end

    % Add self-time as a visible node if significant
    selfTime = timeFromParent - childTimeSum;
    if selfTime > 0.005
        selfNode = struct('name', [entry.FunctionName ' (self)'], ...
            'duration', selfTime, 'start', 0, 'children', {{}});
        children = [children, {selfNode}];
    end

    node = struct('name', entry.FunctionName, 'duration', timeFromParent, ...
        'start', 0, 'children', {children});
    visiting(idx) = false;
end

function promoted = promoteUserChildren(ft, idx, availableTime, isShipping, visiting)
    % Recursively find user-code children under a shipping node.
    % Scale their times proportionally to the available time from the parent call.
    promoted = {};
    entry = ft(idx);

    if visiting(idx) || isempty(entry.Children)
        return;
    end
    visiting(idx) = true;

    % Total time of all children of this shipping node
    totalChildTime = sum([entry.Children.TotalTime]);
    if totalChildTime < 0.001
        visiting(idx) = false;
        return;
    end

    scale = min(availableTime / totalChildTime, 1.0);

    for c = 1:length(entry.Children)
        childIdx = entry.Children(c).Index;
        childTime = entry.Children(c).TotalTime * scale;
        if childTime < 0.001
            continue;
        end

        if isShipping(childIdx)
            % Keep collapsing
            deeper = promoteUserChildren(ft, childIdx, childTime, isShipping, visiting);
            for d = 1:numel(deeper)
                promoted{end+1} = deeper{d}; %#ok<AGROW>
            end
        else
            childNode = buildUserTree(ft, childIdx, childTime, isShipping, visiting);
            promoted{end+1} = childNode; %#ok<AGROW>
        end
    end
    visiting(idx) = false;
end

function [node, offset] = assignStarts(node, offset)
    % Assign sequential start positions to all nodes in the tree
    node.start = offset;
    childOffset = offset;
    for k = 1:numel(node.children)
        [node.children{k}, childOffset] = assignStarts(node.children{k}, childOffset);
    end
    % Return offset after this node
    offset = offset + node.duration;
end
