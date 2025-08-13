function [EEG, com] = pop_EEG_Spectral_Skewness_Time(EEG, COI, AverageChannelsCheck, ExportData, GUIOnOff)
% pop_EEG_Spectral_Skewness_Time
% Time‑domain spectral skewness over sliding windows for selected channels.
%
% Usage:
%   >> [EEG, com] = pop_EEG_Spectral_Skewness_Time(EEG)               % GUI
%   >> [EEG, com] = pop_EEG_Spectral_Skewness_Time(EEG,'1:5 8',0,1,1) % no GUI
%
% Inputs:
%   COI                  channels (e.g., '1:5 8,12' or [1 5 8] or {'Cz','Pz'})
%   AverageChannelsCheck 1 = average selected channels before analysis
%   ExportData           1 = write Excel (csv/txt fallback)
%   GUIOnOff             0/empty → show GUI; 1 → use args (no GUI)
%
% Returns:
%   EEG (unchanged) and com (history string)
% Author: Matthew Phillip Gunn
com = '';
if nargin < 1 || isempty(EEG), error('EEG is required.'); end
useGUI = (nargin < 5) || isempty(GUIOnOff) || ~GUIOnOff;

% ---------- GUI ----------
if useGUI
    row = [.75 1 1];
    geom = {1, row, row, row};
    uilist = { ...
        {'style','text','string','Spectral Skewness — Time Domain','fontweight','bold'} ...
        {'style','text','string','Channels of Interest'} ...
        {'style','edit','string',''} ...
        {'style','text','string','e.g., "1:5 8,12" or "Cz,Pz"'} ...
        {'style','text','string','Average Channels'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Average selected channels into one trace'} ...
        {'style','text','string','Export Data'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Write Excel (fallback CSV/TXT)'} ...
    };
    res = inputgui(geom, uilist, 'title','Spectral Skewness — Time Domain');
    if isempty(res), return; end
    COIraw   = strtrim(res{1});
    AverageChannelsCheck = logical(res{2});
    ExportData = logical(res{3});
else
    COIraw = COI;
end

% ---------- Validate basics ----------
fs = EEG.srate;
if isempty(fs) || ~isfinite(fs) || fs <= 0
    error('EEG.srate must be a positive scalar.');
end

% ---------- Resolve channels (ranges, numbers, or labels) ----------
chanIdx = resolve_coi(COIraw, EEG);
if isempty(chanIdx), error('No valid channels resolved from "%s".', string(COIraw)); end

% ---------- Assemble data (channels x time) ----------
X = EEG.data(chanIdx,:,:);                 % [nChan x pnts x trials]
if size(X,3) > 1
    X = mean(X, 3, 'omitnan');            % average epochs first
end
X = squeeze(X);                            % [nChan x pnts] or [pnts]
if isvector(X), X = X(:).'; end            % row vector

Type = 'TimeDomain';
if AverageChannelsCheck
    X = mean(X, 1, 'omitnan');            % [1 x pnts]
    Type = [Type 'AvgChan'];
end

% ---------- Compute spectral skewness ----------
% Audio Toolbox returns a time series per channel; we also grab the frame-centered
% time vector (seconds). For consistency with other pops, we harmonize lengths.
if size(X,1) == 1
    [SS, T] = spectralSkewness(double(X(:)), fs);
    C = SS(:).';             % 1 x F
    T = T(:).';              % 1 x F, seconds
    labels = { iff(AverageChannelsCheck, avg_label(chanIdx), chan_label(chanIdx(1), EEG)) };
else
    nC = size(X,1);
    C = [];
    T = [];
    for k = 1:nC
        [SSk, tSec] = spectralSkewness(double(X(k,:)).', fs);
        ssk = SSk(:).';
        if isempty(C)
            C = ssk;
            T = tSec(:).';
        else
            L = min(size(C,2), numel(ssk));  % align just in case
            C = [C(:,1:L); ssk(1:L)];
            T = T(1:L);
        end
    end
    if AverageChannelsCheck
        C = mean(C,1,'omitnan');
        labels = { avg_label(chanIdx) };
    else
        labels = arrayfun(@(ii) chan_label(ii,EEG), chanIdx, 'uni', false);
    end
end

if any(isnan(C),'all')
    error('Neurolode Error: invalid skewness values. Check data/windowing.');
end

% ---------- Plot (GUI only) ----------
if useGUI
    figure('Name','Spectral Skewness (Time Domain)');
    plot(T, C.'); grid on;
    xlabel('Time (s)'); ylabel('Skewness');
    legend(labels, 'Location','northwest');
    title('Spectral Skewness (Time Domain)');
end

% ---------- Export ----------
if ExportData
    header = [ {'Channel_or_Group'}, num2cell(T) ];
    if isvector(C)
        sheet = [ header ; [ {labels{1}}, num2cell(C) ] ];
    else
        sheet = header;
        for r = 1:size(C,1)
            sheet = [sheet ; [ {labels{r}}, num2cell(C(r,:)) ]]; %#ok<AGROW>
        end
    end

    base = strip_ext(EEG.filename);
    tag  = iff(AverageChannelsCheck, avg_label(chanIdx), sprintf('Chans_%s', strjoin(string(chanIdx),'_')));
    fname = sprintf('%s_SpectralSkewness_Time_%s.xlsx', base, tag);

    try
        writecell(sheet, fname);
    catch
        try
            fname = sprintf('%s_SpectralSkewness_Time_%s.csv', base, tag);
            writecell(sheet, fname);
        catch
            fname = sprintf('%s_SpectralSkewness_Time_%s.txt', base, tag);
            writecell(sheet, fname, 'Delimiter','tab');
        end
    end
end

% ---------- History ----------
if useGUI
    regions = { string(COIraw), double(AverageChannelsCheck~=0), double(ExportData~=0), 1 };
    com = sprintf('EEG = pop_EEG_Spectral_Skewness_Time(EEG,%s);', vararg2str(regions));
else
    com = sprintf('EEG = pop_EEG_Spectral_Skewness_Time(EEG,%s,%d,%d,1);', ...
        coi_for_history(COIraw), AverageChannelsCheck~=0, ExportData~=0);
end
end

% ================= helpers =================
function idx = resolve_coi(COIraw, EEG)
if isnumeric(COIraw), idx = COIraw(:).'; return; end
if iscell(COIraw), idx = labels2idx(string(COIraw(:)), EEG); return; end
s = string(COIraw); s = strrep(s, ',', ' '); parts = strtrim(split(strtrim(s)));
idx = [];
for i = 1:numel(parts)
    tok = parts{i}; if isempty(tok), continue; end
    r = regexp(tok, '^(\d+)\s*[-:]\s*(\d+)$', 'tokens','once');
    if ~isempty(r)
        a = str2double(r{1}); b = str2double(r{2}); idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
        continue;
    end
    v = str2double(tok);
    if ~isnan(v), idx = [idx, v]; continue; end %#ok<AGROW>
    idx = [idx, labels2idx(string(tok), EEG)]; %#ok<AGROW>
end
idx = unique(idx, 'stable');
end

function ii = labels2idx(lbls, EEG)
if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs)
    error('Channel labels cannot be resolved (EEG.chanlocs empty).');
end
allLabs = string({EEG.chanlocs.labels});
ii = zeros(1,0);
for L = lbls(:).'
    hit = find(strcmpi(allLabs, L), 1);
    if isempty(hit), error('Channel label "%s" not found.', L); end
    ii(end+1) = hit; %#ok<AGROW>
end
end

function s = strip_ext(fn), [~, s, ~] = fileparts(fn); end
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
function y = iff(c,a,b), if c, y = a; else, y = b; end, end
function lab = avg_label(chanIdx), lab = sprintf('AvgChans_%s', strjoin(string(chanIdx),'_')); end
