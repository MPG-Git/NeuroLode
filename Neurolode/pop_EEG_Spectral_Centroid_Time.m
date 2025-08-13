function [EEG, com] = pop_EEG_Spectral_Centroid_Time(EEG, COI, AverageChannelsCheck, ExportData, GUIOnOff)
% pop_EEG_Spectral_Centroid_Time
% Compute spectral centroid over time for selected channels.
%
% Usage:
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Time(EEG)                 % GUI
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Time(EEG,'1:5',0,1,1)     % args
%
% Inputs:
%   EEG  : EEGLAB dataset
%   COI  : channels of interest (e.g. '1:5 8,12' or [1 5 8] or {'Cz','Pz'})
%   AverageChannelsCheck : 1 = average selected channels before analysis
%   ExportData : 1 = write an Excel (fallback CSV/TXT) table
%   GUIOnOff   : 0/empty → show GUI, 1 → no GUI (use args)
%
% Notes:
% - Epochs (3rd dim) are averaged first to get one continuous vector per chan.
% - Spectral centroid is computed with a sliding window (Audio Toolbox):
%       Window = ~200 ms, Hop = ~20 ms.
% - If channels are averaged, one centroid trace is produced (label “AvgChans_*”).
%
% Returns:
%   EEG  : unchanged (returned for EEGLAB contract)
%   com  : history string
%
% Author: Matthew Phillip Gunn (refresh 2025-08-13)

com = '';
if nargin < 1 || isempty(EEG), error('EEG is required.'); end
useGUI = (nargin < 5) || isempty(GUIOnOff) || ~GUIOnOff;

% ---------- GUI ----------
if useGUI
    row = [.75 1 1];
    geom = {1, row, row, row};
    uilist = { ...
        {'style','text','string','Spectral Centroid — Time Domain','fontweight','bold'} ...
        {'style','text','string','Channels of Interest'} ...
        {'style','edit','string',''} ...
        {'style','text','string','e.g., "1:5 8,12" or "Cz,Pz"'} ...
        {'style','text','string','Average Channels'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Average the selected channels into one trace'} ...
        {'style','text','string','Export Data'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Write Excel (fallback CSV/TXT)'} ...
    };
    res = inputgui(geom, uilist, 'title','Spectral Centroid — Time Domain');
    if isempty(res), return; end
    COIraw  = strtrim(res{1});
    AverageChannelsCheck = logical(res{2});
    ExportData = logical(res{3});
else
    COIraw = COI;
end

% ---------- Resolve channel indices ----------
chanIdx = resolve_coi(COIraw, EEG);   % supports ranges, numbers, and labels
if isempty(chanIdx)
    error('No valid channels resolved from input "%s".', string(COIraw));
end

% ---------- Assemble data matrix (channels x time) ----------
X = EEG.data(chanIdx,:,:);                  % [nChan x pnts x trials]
if size(X,3) > 1
    X = mean(X, 3, 'omitnan');             % average epochs
end
X = squeeze(X);                             % [nChan x pnts] (or [pnts], handle later)
if isvector(X), X = X(:).'; end

% Average channels if requested
avgLabel = '';
if AverageChannelsCheck
    X = mean(X, 1, 'omitnan');            % [1 x pnts]
    avgLabel = sprintf('AvgChans_%s', strjoin(string(chanIdx),'_'));
end

% ---------- Parameters for spectral centroid ----------
fs = EEG.srate;
winSamp = max(32, round(0.200 * fs));      % ~200 ms window
hopSamp = max(8,  round(0.020 * fs));      % ~20 ms hop
overlap = max(0, winSamp - hopSamp);
win = hamming(winSamp, 'periodic');

% ---------- Compute centroid traces ----------
% Audio Toolbox: spectralCentroid(x, fs, 'Window',win, 'OverlapLength',overlap)
if size(X,1) == 1
    [cent, tSec] = spectralCentroid(double(X(:)), fs, 'Window', win, 'OverlapLength', overlap);
    C = cent(:).';                           % 1 x F
    T = tSec(:).';                           % 1 x F
    labelList = { iff(AverageChannelsCheck, avgLabel, chan_label(chanIdx(1), EEG)) };
else
    nC = size(X,1);
    C = [];
    for k = 1:nC
        if k == 1
            [cent, tSec] = spectralCentroid(double(X(k,:)).', fs, 'Window', win, 'OverlapLength', overlap);
            T = tSec(:).';
            C = cent(:).';
        else
            cent = spectralCentroid(double(X(k,:)).', fs, 'Window', win, 'OverlapLength', overlap);
            cent = cent(:).';
            % Pad/truncate defensively (should match)
            L = min(numel(C(1,:)), numel(cent));
            C = [C(:,1:L); cent(1:L)];
            T = T(1:L);
        end
    end
    if AverageChannelsCheck
        % should not happen (averaged earlier), but guard anyway
        C = mean(C,1,'omitnan');
        labelList = {avgLabel};
    else
        labelList = arrayfun(@(ii) chan_label(ii,EEG), chanIdx, 'uni', false);
    end
end

% ---------- Plot (GUI calls only) ----------
if useGUI
    figure('Name','Spectral Centroid (Time Domain)');
    plot(T, C.'); grid on;
    xlabel('Time (s)'); ylabel('Centroid (Hz)');
    legend(labelList, 'Location','northwest');
    title('Spectral Centroid (Time Domain)');
end

% ---------- Export ----------
if ExportData
    % Header: first cell, then time stamps (seconds)
    header = [ {'Channel_or_Group'}, num2cell(T) ];
    if isvector(C)
        rows = [ { iff(AverageChannelsCheck, avgLabel, labelList{1}) }, num2cell(C) ];
        sheet = [ header ; rows ];
    else
        sheet = header;
        for r = 1:size(C,1)
            sheet = [sheet; [ {labelList{r}}, num2cell(C(r,:)) ]]; %#ok<AGROW>
        end
    end

    base = strip_ext(EEG.filename);
    tag  = iff(AverageChannelsCheck, avgLabel, sprintf('Chans_%s', strjoin(string(chanIdx),'_')));
    fname = sprintf('%s_SpectralCentroid_Time_%s.xlsx', base, tag);

    try
        writecell(sheet, fname);
    catch
        try
            fname = sprintf('%s_SpectralCentroid_Time_%s.csv', base, tag);
            writecell(sheet, fname);
        catch
            fname = sprintf('%s_SpectralCentroid_Time_%s.txt', base, tag);
            writecell(sheet, fname, 'Delimiter','tab');
        end
    end
end

% ---------- History string ----------
if useGUI
    regions = { string(COIraw), double(AverageChannelsCheck ~= 0), double(ExportData ~= 0), 1 };
    com = sprintf('EEG = pop_EEG_Spectral_Centroid_Time(EEG,%s);', vararg2str(regions));
else
    com = sprintf('EEG = pop_EEG_Spectral_Centroid_Time(EEG,%s,%d,%d,1);', ...
        coi_for_history(COIraw), AverageChannelsCheck~=0, ExportData~=0);
end

end % === main ===

% ---------------- helpers ----------------
function idx = resolve_coi(COIraw, EEG)
% Accept numbers, ranges, and/or labels
if isnumeric(COIraw)
    idx = COIraw(:).';
    return;
end
if iscell(COIraw)
    idx = labels2idx(string(COIraw(:)), EEG);
    return;
end
s = string(COIraw);
% split on spaces/commas
s = strrep(s, ',', ' ');
parts = strtrim(split(strtrim(s)));
idx = [];
for i = 1:numel(parts)
    tok = parts{i};
    if isempty(tok), continue; end
    % range?
    r = regexp(tok, '^(\d+)\s*[-:]\s*(\d+)$', 'tokens', 'once');
    if ~isempty(r)
        a = str2double(r{1}); b = str2double(r{2});
        idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
        continue;
    end
    % numeric?
    v = str2double(tok);
    if ~isnan(v)
        idx = [idx, v]; %#ok<AGROW>
        continue;
    end
    % label
    idx = [idx, labels2idx(string(tok), EEG)]; %#ok<AGROW>
end
idx = unique(idx, 'stable');
end

function ii = labels2idx(lbls, EEG)
if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs)
    error('Channel labels cannot be resolved: EEG.chanlocs is empty.');
end
allLabs = string({EEG.chanlocs.labels});
ii = zeros(1,0);
for L = lbls(:).'
    hit = find(strcmpi(allLabs, L), 1);
    if isempty(hit), error('Channel label "%s" not found.', L); end
    ii(end+1) = hit; %#ok<AGROW>
end
end

function lab = chan_label(idx, EEG)
if isfield(EEG,'chanlocs') && numel(EEG.chanlocs) >= idx && ~isempty(EEG.chanlocs(idx).labels)
    lab = char(EEG.chanlocs(idx).labels);
else
    lab = sprintf('Chan_%d', idx);
end
end

function s = coi_for_history(COIraw)
if isnumeric(COIraw)
    s = mat2str(COIraw);
elseif iscell(COIraw)
    q = cellfun(@(x) ['''' char(x) ''''], COIraw, 'uni', false);
    s = ['{' strjoin(q,' ') '}'];
else
    s = ['''' char(string(COIraw)) ''''];
end
end

function s = strip_ext(fn)
[~, s, ~] = fileparts(fn);
end

function y = iff(c,a,b)
if c, y = a; else, y = b; end
end
