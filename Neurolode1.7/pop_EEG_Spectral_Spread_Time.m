function [EEG, com] = pop_EEG_Spectral_Spread_Time(EEG, COI, AverageChannelsCheck, ExportData, GUIOnOff)
% pop_EEG_Spectral_Spread_Time
% Compute time‑domain spectral spread (spectralSpread) for selected channels.
%
% Usage:
%   >> [EEG, com] = pop_EEG_Spectral_Spread_Time(EEG)                 % GUI
%   >> [EEG, com] = pop_EEG_Spectral_Spread_Time(EEG,'1:5 Cz',1,1,1)  % no GUI
%
% Inputs:
%   COI  : channels (e.g., '1:5 8,12' or [1 5 8] or {'Cz','Pz'})
%   AverageChannelsCheck : 1 averages selected channels to one trace
%   ExportData           : 1 exports table (xlsx, else csv/txt fallback)
%   GUIOnOff             : 1 skip GUI and use args; otherwise GUI shown
%
% Returns:
%   EEG (unchanged) and com history string.
% Author: Matthew Phillip Gunn

com = '';
if nargin < 1 || isempty(EEG), error('EEG is required.'); end
Type  = 'TimeDomain';
useGUI = (nargin < 5) || isempty(GUIOnOff) || ~GUIOnOff;

% ---------- GUI ----------
if useGUI
    row   = [.75 1 1];
    geom  = {1, row, row, row};
    uilist = { ...
        {'style','text','string','Spectral Spread — Time Domain','fontweight','bold'} ...
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
    res = inputgui(geom, uilist, 'title','Spectral Spread — Time Domain');
    if isempty(res), return; end
    COIraw               = strtrim(res{1});
    AverageChannelsCheck = logical(res{2});
    ExportData           = logical(res{3});
else
    COIraw = COI;
end

% ---------- checks ----------
fs = EEG.srate;
if isempty(fs) || ~isfinite(fs) || fs <= 0
    error('EEG.srate must be a positive scalar.');
end

% ---------- resolve channels ----------
chanIdx = resolve_coi(COIraw, EEG);
if isempty(chanIdx), error('No valid channels resolved from "%s".', string(COIraw)); end

% ---------- prepare data (chan x time) ----------
X = EEG.data(chanIdx,:,:);                % [nChan x pnts x trials]
if size(X,3) > 1
    X = mean(X,3,'omitnan');             % average epochs first
end
X = squeeze(X);                           % -> [nChan x pnts] or [pnts]
if isvector(X), X = X(:).'; end          % ensure row if single chan

if AverageChannelsCheck
    X = mean(X,1,'omitnan');             % -> [1 x pnts]
    Type = [Type 'AvgChan'];
end

% ---------- compute spectral spread ----------
C = []; labels = {};
if size(X,1) == 1
    SS = spectralSpread(double(X(:)), fs);      % nFrames x 1
    C  = SS(:).';                                % 1 x nFrames
    labels = { avg_or_first_label(chanIdx, EEG, AverageChannelsCheck) };
else
    nC = size(X,1);
    tmp = cell(1,nC);
    Lmin = inf;
    for k = 1:nC
        SSk = spectralSpread(double(X(k,:)).', fs);
        tmp{k} = SSk(:).';
        Lmin = min(Lmin, numel(tmp{k}));
    end
    C = zeros(nC, Lmin);
    for k = 1:nC, C(k,:) = tmp{k}(1:Lmin); end
    if AverageChannelsCheck
        C = mean(C,1,'omitnan');
        labels = { avg_or_first_label(chanIdx, EEG, 1) };
    else
        labels = arrayfun(@(ii) chan_label(ii,EEG), chanIdx, 'uni', false);
    end
end

if any(isnan(C),'all')
    error('Neurolode Error: invalid spread values (NaNs).');
end

% time axis to match frames
t = linspace(EEG.xmin, EEG.xmax, size(C,2));

% ---------- plot (GUI only) ----------
if useGUI
    figure('Name','Spectral Spread (Time Domain)');
    plot(t, C.'); grid on;
    xlabel('Time (s)'); ylabel('Spread (Hz)');
    legend(labels,'Location','northwest');
    title('Spectral Spread (Time Domain)');
end

% ---------- export ----------
if nargin >= 4 && ~isempty(ExportData) && ExportData
    header = [ {'Channel_or_Group'}, num2cell(t) ];
    if isvector(C)
        sheet = [header ; [ {labels{1}}, num2cell(C) ] ];
    else
        sheet = header;
        for r = 1:size(C,1)
            sheet = [sheet ; [ {labels{r}}, num2cell(C(r,:)) ]]; %#ok<AGROW>
        end
    end
    base = strip_ext(EEG.filename);
    tag  = export_tag(chanIdx, EEG, AverageChannelsCheck);
    fname = sprintf('%s_SpectralSpread_Time_%s.xlsx', base, tag);
    if ~try_writecell(sheet, fname)
        fname = sprintf('%s_SpectralSpread_Time_%s.csv', base, tag);
        if ~try_writecell(sheet, fname)
            fname = sprintf('%s_SpectralSpread_Time_%s.txt', base, tag);
            try_writecell(sheet, fname, '\t'); %#ok<NASGU>
        end
    end
end

% ---------- history ----------
if useGUI
    regions = { string(COIraw), double(AverageChannelsCheck~=0), double(ExportData~=0), 1 }; % Time
    com = sprintf('EEG = pop_EEG_Spectral_Spread_Time(EEG,%s);', vararg2str(regions));
else
    com = sprintf('EEG = pop_EEG_Spectral_Spread_Time(EEG,%s,%d,%d,1);', ...
        coi_for_history(COIraw), AverageChannelsCheck~=0, ExportData~=0);
end
end

% ================= helpers =================
function idx = resolve_coi(COIraw, EEG)
% Accept numeric, cellstr of labels, or string with ranges/lists and labels.
if isnumeric(COIraw)
    idx = unique(COIraw(:).','stable'); return;
end
if iscell(COIraw)
    idx = labels2idx(string(COIraw(:)), EEG); return;
end
s = string(COIraw); s = strrep(s, ',', ' ');
parts = strtrim(split(strtrim(s)));
idx = [];
for i = 1:numel(parts)
    tok = parts{i}; if tok==""; continue; end
    r = regexp(tok, '^(\d+)\s*[-:]\s*(\d+)$', 'tokens','once');
    if ~isempty(r)
        a = str2double(r{1}); b = str2double(r{2});
        idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
        continue;
    end
    v = str2double(tok);
    if ~isnan(v)
        idx = [idx, v]; %#ok<AGROW>
    else
        idx = [idx, labels2idx(tok, EEG)]; %#ok<AGROW>
    end
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

function s = chan_label(ii, EEG)
if isfield(EEG,'chanlocs') && ~isempty(EEG.chanlocs) && ii>=1 && ii<=numel(EEG.chanlocs)
    lab = EEG.chanlocs(ii).labels; if ~isempty(lab), s = char(lab); return; end
end
s = sprintf('Chan_%d', ii);
end

function s = avg_or_first_label(idx, EEG, avgFlag)
if avgFlag
    if isfield(EEG,'chanlocs') && ~isempty(EEG.chanlocs)
        labs = arrayfun(@(ii) EEG.chanlocs(ii).labels, idx, 'uni', false);
        labs = labs(~cellfun('isempty',labs));
        if ~isempty(labs), s = sprintf('Avg(%s)', strjoin(labs,',')); return; end
    end
    s = sprintf('Avg(Chans_%s)', strjoin(string(idx),'_'));
else
    s = chan_label(idx(1), EEG);
end
end

function tag = export_tag(idx, EEG, avgFlag)
if avgFlag
    tag = 'AvgSel';
else
    tag = sprintf('Chans_%s', strjoin(string(idx),'_'));
end
end

function tf = try_writecell(sheet, fname, delim)
if nargin < 3, delim = ''; end
tf = true;
try
    if endsWith(lower(fname), '.xlsx')
        writecell(sheet, fname);
    elseif endsWith(lower(fname), '.csv')
        writecell(sheet, fname); % MATLAB chooses comma
    else
        if isempty(delim), delim = '\t'; end
        writecell(sheet, fname, 'Delimiter', delim);
    end
catch
    tf = false;
end
end

function s = strip_ext(fn)
d = find(fn=='.',1,'last');
if isempty(d), s = fn; else, s = fn(1:d-1); end
end

function s = coi_for_history(COIraw)
if isnumeric(COIraw)
    s = mat2str(COIraw);
elseif iscell(COIraw)
    s = ['{' strjoin(string(COIraw), ',') '}'];
else
    s = ['''' char(string(COIraw)) ''''];
end
end
