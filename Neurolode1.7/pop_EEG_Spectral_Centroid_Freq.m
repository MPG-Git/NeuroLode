function [EEG, com] = pop_EEG_Spectral_Centroid_Freq(EEG, COI, AverageChannelsCheck, ExportData, Frames2buffer, OverlapFrames, GUIOnOff)
% pop_EEG_Spectral_Centroid_Freq
% Time-resolved spectral centroid using octave-band power (frequency domain).
%
% Usage:
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Freq(EEG)  % GUI
%   >> [EEG, com] = pop_EEG_Spectral_Centroid_Freq(EEG,'1:5 8',0,1,200,20,1)
%
% Inputs:
%   COI                  channels (e.g., '1:5 8,12' or [1 5 8] or {'Cz','Pz'})
%   AverageChannelsCheck 1 = average selected channels before analysis
%   ExportData           1 = write Excel (csv/txt fallback)
%   Frames2buffer        window length in ms (default 200)
%   OverlapFrames        overlap length in ms (default 20)
%   GUIOnOff             0/empty → show GUI; 1 → no GUI
%
% Notes:
% - Epochs (3rd dim) are averaged first → one continuous vector per channel.
% - For each time frame, we compute octave-band power via poctave, then
%   spectral centroid over the octave centers weighted by band power.
% Author: Matthew Phillip Gunn
com = '';
if nargin < 1 || isempty(EEG), error('EEG is required.'); end
useGUI = (nargin < 7) || isempty(GUIOnOff) || ~GUIOnOff;

% ---------------- GUI ----------------
if useGUI
    row = [.75 1 1];
    geom = {1, row, row, row, row, row};
    uilist = { ...
        {'style','text','string','Spectral Centroid — Frequency Domain','fontweight','bold'} ...
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
        {'style','text','string','~10%% of window'} ...
    };
    res = inputgui(geom, uilist, 'title','Spectral Centroid — Frequency Domain');
    if isempty(res), return; end
    COIraw   = strtrim(res{1});
    AverageChannelsCheck = logical(res{2});
    ExportData = logical(res{3});
    Frames2buffer = str2double(res{4});
    OverlapFrames = str2double(res{5});
else
    COIraw = COI;
    if nargin < 5 || isempty(Frames2buffer), Frames2buffer = 200; end
    if nargin < 6 || isempty(OverlapFrames),  OverlapFrames  = 20;  end
end

% ------------- validate -------------
fs = EEG.srate;
if isempty(fs) || ~isfinite(fs) || fs <= 0, error('EEG.srate must be positive.'); end
mustPos = @(x,n) assert(isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>0,'%s must be a positive scalar.',n);
mustNonneg = @(x,n) assert(isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0,'%s must be non-negative.',n);
mustPos(Frames2buffer,'Window (ms)');
mustNonneg(OverlapFrames,'Overlap (ms)');
winSamp = max(2, round(Frames2buffer/1000*fs));
ovlSamp = round(OverlapFrames/1000*fs);
assert(ovlSamp < winSamp, 'Overlap must be strictly less than window.');

% ------------- channels -------------
chanIdx = resolve_coi(COIraw, EEG);
if isempty(chanIdx), error('No valid channels resolved from "%s".', string(COIraw)); end

% ------------- data (channels x time) -------------
X = EEG.data(chanIdx,:,:);           % [nChan x pnts x trials]
if size(X,3) > 1, X = mean(X,3,'omitnan'); end
X = squeeze(X);                      % [nChan x pnts] or [pnts]
if isvector(X), X = X(:).'; end

Type = 'FreqDomain';
if AverageChannelsCheck
    X = mean(X,1,'omitnan');        % [1 x pnts]
    Type = [Type 'AvgChan'];
end

% ------------- frame indexing -------------
N = size(X,2);
hop = winSamp - ovlSamp;
nFrames = 1 + floor((N - winSamp)/hop);
if nFrames < 1
    error('Signal shorter than one window (%d samples).', winSamp);
end
frameIdx = bsxfun(@plus, (0:winSamp-1).', 1 + (0:nFrames-1)*hop);  % [winSamp x nFrames]
T = ( (1 + (0:nFrames-1)*hop) + (winSamp/2) ) / fs;                % time (s) at frame centers

% ------------- centroid per frame -------------
if size(X,1) == 1
    c = zeros(1, nFrames);
    for f = 1:nFrames
        seg = double(X(frameIdx(:,f)));
        % octave-band power for this frame
        [p, cf] = poctave(seg, fs);         % p: power per band (column), cf: center freqs
        % centroid over octave centers (Hz) weighted by power
        c(f) = spectralCentroid(p(:).', cf(:).');  % returns scalar
    end
    C = c;
    labels = { iff(AverageChannelsCheck, avg_label(chanIdx), chan_label(chanIdx(1), EEG)) };
else
    nC = size(X,1);
    C = zeros(nC, nFrames);
    for k = 1:nC
        xk = X(k,:);
        for f = 1:nFrames
            seg = double(xk(frameIdx(:,f)));
            [p, cf] = poctave(seg, fs);
            C(k,f) = spectralCentroid(p(:).', cf(:).');
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
    error('Neurolode Error: invalid centroid values (check window/overlap).');
end

% ------------- plot (GUI only) -------------
if useGUI
    figure('Name','Spectral Centroid (Frequency Domain)');
    plot(T, C.'); grid on;
    xlabel('Time (s)'); ylabel('Centroid (Hz)');
    legend(labels, 'Location','northwest');
    title(sprintf('Freq-domain centroid (Window %d ms, Overlap %d ms)', ...
          round(Frames2buffer), round(OverlapFrames)));
end

% ------------- export -------------
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
    fname = sprintf('%s_SpectralCentroid_Freq_%s.xlsx', base, tag);
    try
        writecell(sheet, fname);
    catch
        try
            fname = sprintf('%s_SpectralCentroid_Freq_%s.csv', base, tag);
            writecell(sheet, fname);
        catch
            fname = sprintf('%s_SpectralCentroid_Freq_%s.txt', base, tag);
            writecell(sheet, fname, 'Delimiter','tab');
        end
    end
end

% ------------- history -------------
if useGUI
    regions = { string(COIraw), double(AverageChannelsCheck~=0), double(ExportData~=0), ...
                Frames2buffer, OverlapFrames, 1 };
    com = sprintf('EEG = pop_EEG_Spectral_Centroid_Freq(EEG,%s);', vararg2str(regions));
else
    com = sprintf('EEG = pop_EEG_Spectral_Centroid_Freq(EEG,%s,%d,%d,%g,%g,1);', ...
          coi_for_history(COIraw), AverageChannelsCheck~=0, ExportData~=0, ...
          Frames2buffer, OverlapFrames);
end
end

% ---------------- helpers ----------------
function idx = resolve_coi(COIraw, EEG)
if isnumeric(COIraw), idx = COIraw(:).'; return; end
if iscell(COIraw), idx = labels2idx(string(COIraw(:)), EEG); return; end
s = string(COIraw); s = strrep(s, ',', ' '); parts = strtrim(split(strtrim(s)));
idx = [];
for i = 1:numel(parts)
    tok = parts{i}; if isempty(tok), continue; end
    r = regexp(tok, '^(\d+)\s*[-:]\s*(\d+)$', 'tokens','once');
    if ~isempty(r)
        a = str2double(r{1}); b = str2double(r{2});
        idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
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
