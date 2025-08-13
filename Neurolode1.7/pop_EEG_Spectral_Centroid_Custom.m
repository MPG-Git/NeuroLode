function [EEG, com] = pop_EEG_Spectral_Centroid_Custom(EEG, COI, AverageChannelsCheck, ExportData, Frames2buffer, OverlapFrames, HzRange, GUIOnOff)
% pop_EEG_Spectral_Centroid_Custom
% Spectral centroid over time with custom window/overlap/range.
%
% Usage:
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Custom(EEG)  % GUI
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Custom(EEG,'1:5',1,1,200,20,[1 40],1)
%
% Inputs
%   COI                : channels (e.g., '1:5 8,12' or [1 5 8] or {'Cz','Pz'})
%   AverageChannelsCheck : 1=average selected channels before analysis
%   ExportData         : 1=write Excel (csv/txt fallback)
%   Frames2buffer      : window length in ms (e.g., 200)
%   OverlapFrames      : overlap length in ms (e.g., 20)
%   HzRange            : [fmin fmax] in Hz (e.g., [1 40])
%   GUIOnOff           : 0/empty → show GUI; 1 → use args (no GUI)
%
% Returns
%   EEG (unchanged) and com (history string)
% Author: Matthew Phillip Gunn
com = '';
if nargin < 1 || isempty(EEG), error('EEG is required.'); end
useGUI = (nargin < 8) || isempty(GUIOnOff) || ~GUIOnOff;

% ---------- GUI ----------
if useGUI
    row = [.75 1 1];
    geom = {1, row, row, row, row, row, row};
    uilist = { ...
        {'style','text','string','Spectral Centroid — Custom','fontweight','bold'} ...
        {'style','text','string','Channels of Interest'} ...
        {'style','edit','string',''} ...
        {'style','text','string','e.g., "1:5 8,12" or "Cz,Pz"'} ...
        {'style','text','string','Average Channels'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Average selected channels into one trace'} ...
        {'style','text','string','Export Data'} ...
        {'style','checkbox','string',''} ...
        {'style','text','string','Write Excel (fallback CSV/TXT)'} ...
        {'style','text','string','Window length (ms)'} ...
        {'style','edit','string','200'} ...
        {'style','text','string','~200 ms recommended'} ...
        {'style','text','string','Overlap (ms)'} ...
        {'style','edit','string','20'} ...
        {'style','text','string','~10% of window'} ...
        {'style','text','string','Centroid Hz range [min max]'} ...
        {'style','edit','string','[1 40]'} ...
        {'style','text','string','e.g., [1 40]'} ...
    };
    res = inputgui(geom, uilist, 'title','Spectral Centroid — Custom');
    if isempty(res), return; end

    COIraw   = strtrim(res{1});
    AverageChannelsCheck = logical(res{2});
    ExportData = logical(res{3});
    Frames2buffer = str2double(res{4});
    OverlapFrames = str2double(res{5});
    HzRange = str2num(res{6}); %#ok<ST2NM>  % expect [fmin fmax]
else
    COIraw = COI;
    if ischar(HzRange) || isstring(HzRange), HzRange = str2num(char(HzRange)); end %#ok<ST2NM>
end

% ---------- Validate inputs ----------
fs = EEG.srate;
if isempty(fs) || ~isfinite(fs) || fs <= 0
    error('EEG.srate must be a positive scalar.');
end

mustPos = @(x,name) assert(isnumeric(x) && isscalar(x) && isfinite(x) && x>0, '%s must be a positive scalar.', name);
mustNonneg = @(x,name) assert(isnumeric(x) && isscalar(x) && isfinite(x) && x>=0, '%s must be non-negative.', name);

mustPos(Frames2buffer, 'Frames2buffer (ms)');
mustNonneg(OverlapFrames, 'OverlapFrames (ms)');

assert(isnumeric(HzRange) && numel(HzRange)==2 && all(isfinite(HzRange)) && HzRange(1) < HzRange(2), ...
    'HzRange must be a 1x2 numeric [fmin fmax] with fmin < fmax.');
assert(HzRange(2) <= fs/2 + 1e-6, 'HzRange upper bound must be <= Nyquist (%.2f Hz).', fs/2);

% samples
winSamp  = max(2, round(Frames2buffer/1000 * fs));
ovlSamp  = round(OverlapFrames/1000 * fs);
assert(ovlSamp < winSamp, 'Overlap (ms) must be strictly less than window (ms).');

% ---------- Resolve channels ----------
chanIdx = resolve_coi(COIraw, EEG);
if isempty(chanIdx), error('No valid channels resolved from input "%s".', string(COIraw)); end

% ---------- Data assembly (channels x time) ----------
X = EEG.data(chanIdx,:,:);                    % [nChan x pnts x trials]
if size(X,3) > 1
    X = mean(X, 3, 'omitnan');               % avg epochs
end
X = squeeze(X);                               % [nChan x pnts] or [pnts]
if isvector(X), X = X(:).'; end

% Average channels if requested
Type = 'Custom';
if AverageChannelsCheck
    X = mean(X, 1, 'omitnan');               % [1 x pnts]
    Type = [Type 'AvgChan'];
end

% ---------- Compute centroid ----------
win = hamming(winSamp, 'periodic');
fmin = HzRange(1); fmax = HzRange(2);

if size(X,1) == 1
    [cent, tSec] = spectralCentroid(double(X(:)), fs, ...
        'Window', win, 'OverlapLength', ovlSamp, 'Range', [fmin fmax]);
    C = cent(:).';   T = tSec(:).';
    labels = { iff(AverageChannelsCheck, avg_label(chanIdx), chan_label(chanIdx(1), EEG)) };
else
    nC = size(X,1);
    C = [];
    for k = 1:nC
        if k == 1
            [cent, tSec] = spectralCentroid(double(X(k,:)).', fs, ...
                'Window', win, 'OverlapLength', ovlSamp, 'Range', [fmin fmax]);
            T = tSec(:).'; C = cent(:).';
        else
            cent = spectralCentroid(double(X(k,:)).', fs, ...
                'Window', win, 'OverlapLength', ovlSamp, 'Range', [fmin fmax]);
            cent = cent(:).';
            L = min(size(C,2), numel(cent));
            C = [C(:,1:L); cent(1:L)];
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
    error('Neurolode Error: Invalid centroid values. Check HzRange/window/overlap.');
end

% ---------- Plot (GUI only) ----------
if useGUI
    figure('Name','Spectral Centroid (Custom)');
    plot(T, C.'); grid on;
    xlabel('Time (s)'); ylabel('Centroid (Hz)');
    legend(labels, 'Location','northwest');
    title(sprintf('Spectral Centroid (Window %d ms, Overlap %d ms, Range [%g %g] Hz)', ...
        round(1000*winSamp/fs), round(1000*ovlSamp/fs), fmin, fmax));
end

% ---------- Export ----------
if ExportData
    header = [ {'Channel_or_Group'}, num2cell(T) ];
    if isvector(C)
        rows = [ {labels{1}}, num2cell(C) ];
        sheet = [ header ; rows ];
    else
        sheet = header;
        for r = 1:size(C,1)
            sheet = [sheet; [ {labels{r}}, num2cell(C(r,:)) ]]; %#ok<AGROW>
        end
    end

    base = strip_ext(EEG.filename);
    tag  = iff(AverageChannelsCheck, avg_label(chanIdx), sprintf('Chans_%s', strjoin(string(chanIdx),'_')));
    fname = sprintf('%s_SpectralCentroid_Custom_%s.xlsx', base, tag);

    try
        writecell(sheet, fname);
    catch
        try
            fname = sprintf('%s_SpectralCentroid_Custom_%s.csv', base, tag);
            writecell(sheet, fname);
        catch
            fname = sprintf('%s_SpectralCentroid_Custom_%s.txt', base, tag);
            writecell(sheet, fname, 'Delimiter','tab');
        end
    end
end

% ---------- History ----------
if useGUI
    regions = { string(COIraw), double(AverageChannelsCheck~=0), double(ExportData~=0), ...
                Frames2buffer, OverlapFrames, [fmin fmax], 1 };
    com = sprintf('EEG = pop_EEG_Spectral_Centroid_Custom(EEG,%s);', vararg2str(regions));
else
    com = sprintf(['EEG = pop_EEG_Spectral_Centroid_Custom(EEG,%s,%d,%d,%g,%g,[%g %g],1);'], ...
        coi_for_history(COIraw), AverageChannelsCheck~=0, ExportData~=0, ...
        Frames2buffer, OverlapFrames, fmin, fmax);
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

function s = strip_ext(fn)
[~, s, ~] = fileparts(fn);
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

function y = iff(c,a,b), if c, y = a; else, y = b; end, end
function lab = avg_label(chanIdx), lab = sprintf('AvgChans_%s', strjoin(string(chanIdx),'_')); end
