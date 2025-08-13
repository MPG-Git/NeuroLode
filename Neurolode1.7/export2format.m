function [EEG, outpath] = export2format(EEG, CoI, GA, AC, TS, FileType, outdir)
% export2format  Export selected EEG channels to Excel / CSV / TXT / DAT.
%
% Usage:
%   >> [EEG, outpath] = export2format(EEG, CoI, GA, AC, TS, FileType, outdir)
%
% Inputs
%   EEG      : EEGLAB dataset
%   CoI      : Channels of interest. Accepts:
%                - string like '1,2,5-8 12:14 Cz,Pz' (ranges, spaces, commas)
%                - numeric vector (e.g., [1 2 5 6 7 8 12 13 14])
%                - cellstr of labels (e.g., {'Cz','Pz'})
%   GA       : Grand-average epochs? (1=yes, 0=no)
%   AC       : Average listed channels? (1=yes, 0=no)
%   TS       : Append timestamp to filename? (1=yes, 0=no)
%   FileType : '.xlsx' | '.csv' | '.txt' | '.dat'  (case-insensitive)
%   outdir   : (optional) output folder. Default: pwd
%
% Outputs
%   EEG      : unchanged (returned for convenience)
%   outpath  : full path of the written file
%
% Modes (replicating your original logic):
%   GA=1 & AC=1     → mean over epochs, then mean over CoI → 1×pnts
%   GA=1 & AC=0     → mean over epochs, keep each channel → nChan×pnts
%   GA=0 & AC=1     → mean over CoI, keep epochs (concat along time) → 1×(pnts*trials)
%   GA=0 & AC=0     → keep each channel, keep epochs (concat along time) → nChan×(pnts*trials)
%
% Author: Matthew Phillip Gunn (refreshed 2025-08-13)

outpath = '';

% -------- defaults / sanitation --------
if nargin < 7 || isempty(outdir), outdir = pwd; end
if nargin < 6 || isempty(FileType), FileType = '.xlsx'; end
if nargin < 5 || isempty(TS), TS = 0; end
if nargin < 4 || isempty(AC), AC = 0; end
if nargin < 3 || isempty(GA), GA = 0; end

% Normalize extension
[~,~,ext] = fileparts(lower(strtrim(FileType)));
if isempty(ext), ext = lower(strtrim(FileType)); end
if ~startsWith(ext,'.'), ext = ['.' ext]; end

% -------- parse CoI to numeric indices --------
chanIdx = parse_coi(CoI, EEG);

if isempty(chanIdx)
    error('export2format: No valid channels resolved from CoI input.');
end

% -------- slice data --------
X = EEG.data(chanIdx,:,:);                % [nChan x pnts x trials]
nChan = size(X,1);
pnts  = size(X,2);
tr    = size(X,3);

% -------- compute per-mode --------
% Build a label suffix and output numeric matrix "Y" (rows = channels or 1)
chanSuffix = sprintf('Chans_%s', strjoin(arrayfun(@num2str, chanIdx, 'uni', false),'_'));

if GA==1 && AC==1
    % mean epochs -> mean channels → 1 x pnts
    Y = squeeze(mean(mean(X,3,'omitnan'),1,'omitnan')).';   % [1 x pnts]
    header = time_header(EEG, pnts, 1, 'Filename');         % single epoch header
    rowlab = sprintf('AvgChans_%s', strjoin(arrayfun(@num2str, chanIdx,'uni',false),'_'));
    dataCell = [ {compose_filename(EEG, rowlab, TS)} num2cell(Y) ];

elseif GA==1 && AC==0
    % mean epochs → keep channels → nChan x pnts
    Y = squeeze(mean(X,3,'omitnan'));                       % [nChan x pnts]
    header = time_header(EEG, pnts, 1, 'Channel#_DataSet');
    rownames = strcat(string(chanIdx),'_Chan_', strip_ext(EEG.filename));
    dataCell = [ rownames num2cell(Y) ];

elseif GA==0 && AC==1
    % mean channels → keep epochs (concat time) → 1 x (pnts*tr)
    Y = squeeze(mean(X,1,'omitnan'));                       % [1 x pnts x tr] → [pnts x tr]
    Y = reshape(Y, 1, pnts*tr);                             % [1 x pnts*tr]
    header = time_header(EEG, pnts, tr, 'Channels_DataSet');
    rowlab = sprintf('AvgChans_%s', strjoin(arrayfun(@num2str, chanIdx,'uni',false),'_'));
    dataCell = [ {compose_filename(EEG, rowlab, TS)} num2cell(Y) ];

else
    % GA=0 & AC=0: keep channels, keep epochs (concat time) → nChan x (pnts*tr)
    if tr > 1
        Y = reshape(X, nChan, pnts*tr);                     % concat along time
    else
        Y = squeeze(X);                                     % [nChan x pnts]
    end
    header = time_header(EEG, pnts, tr, 'Channel#_DataSet');
    rownames = strcat(string(chanIdx),'_Chan_', strip_ext(EEG.filename));
    dataCell = [ rownames num2cell(Y) ];
end

% First row of sheet is header, then rows of data
sheet = [ header ; dataCell ];

% -------- choose base filename --------
base = sprintf('%s_%s', strip_ext(EEG.filename), chanSuffix);
if TS
    base = sprintf('%s_%s', base, datestr(now,'mm_dd_yyyy-HHMM'));
end
fname = [base ext];
outpath = fullfile(outdir, fname);

% -------- write file --------
switch ext
    case {'.xlsx','.xls'}
        writecell(sheet, outpath, 'WriteMode','overwrite');
    case {'.csv'}
        writecell(sheet, outpath);
    case {'.txt'}
        writecell(sheet, outpath, 'Delimiter','tab');
    case {'.dat'}
        % DAT: common to want numeric matrix; we’ll write a mixed header row
        % line, then numeric rows only (no row labels). Fall back to full
        % cell if needed.
        try
            % header
            fid = fopen(outpath,'w');
            assert(fid>0, 'export2format: cannot open %s', outpath);
            hdr = sheet(1,:);
            fprintf(fid, '%s', string(hdr{1}));
            for i=2:numel(hdr), fprintf(fid, '\t%s', string(hdr{i})); end
            fprintf(fid, '\n');
            % numeric block: drop the first col (rownames) and enforce numeric
            numblock = cell2mat(sheet(2:end,2:end));
            dlmwrite(outpath, numblock, '-append','delimiter','\t','precision',9);
            fclose(fid);
        catch ME
            warning('DAT numeric write failed (%s). Writing as tab-delimited text instead.', ME.message);
            writecell(sheet, outpath, 'Delimiter','tab');
        end
    otherwise
        warning('Unknown extension "%s". Writing .csv instead.', ext);
        ext = '.csv';
        outpath = fullfile(outdir, [base ext]);
        writecell(sheet, outpath);
end
end

% ===================== helpers =====================

function idx = parse_coi(CoI, EEG)
% Return numeric channel indices (1-based) resolving labels if given
if isnumeric(CoI)
    idx = CoI(:).';
    return;
end
if iscell(CoI)
    % assume labels
    labels = string(CoI(:));
    idx = label2index(labels, EEG);
    return;
end
% string with ranges/labels
s = string(CoI);
s = strrep(s, ',', ' ');
s = regexprep(s, '\s+', ' ');
parts = strtrim(strsplit(strtrim(s)));
idx = [];
for k=1:numel(parts)
    tok = parts{k};
    if contains(tok,{'-','~',':'})
        nums = regexp(tok,'(\d+)[-~:](\d+)','tokens','once');
        if ~isempty(nums)
            a = str2double(nums{1}); b = str2double(nums{2});
            idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
            continue;
        end
    end
    v = str2double(tok);
    if ~isnan(v)
        idx = [idx, v]; %#ok<AGROW>
    else
        % treat as label
        ii = label2index(string(tok), EEG);
        idx = [idx, ii]; %#ok<AGROW>
    end
end
idx = unique(idx, 'stable');
end

function ii = label2index(labels, EEG)
% map labels (string array) to numeric indices via EEG.chanlocs
ii = [];
if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs)
    error('Channel labels cannot be resolved: EEG.chanlocs is empty.');
end
allLabs = string({EEG.chanlocs.labels});
for L = labels(:).'
    hit = find(strcmpi(allLabs, L), 1);
    if isempty(hit)
        error('Channel label "%s" not found in EEG.chanlocs.', L);
    end
    ii = [ii, hit]; %#ok<AGROW>
end
end

function header = time_header(EEG, pnts, trials, firstLabel)
% Build header row: {firstLabel, t1, t2, ...} with per-epoch replication
% EEGLAB stores times in ms; xmin/xmax in seconds for epochs.
if isfield(EEG,'times') && ~isempty(EEG.times) && numel(EEG.times) >= pnts
    tms = double(EEG.times(:)).';
else
    % derive from xmin/xmax (sec) to ms
    if ~isfield(EEG,'xmin') || ~isfield(EEG,'xmax') || isempty(EEG.srate)
        % fallback: 0..pnts-1 samples in ms
        tms = (0:pnts-1) * 1000 / max(EEG.srate,1);
    else
        t = linspace(EEG.xmin, EEG.xmax, pnts);  % seconds
        tms = t * 1000;
    end
end
% replicate per epoch when concatenating trials along time
tRow = repmat(num2cell(tms), 1, trials);
header = [ {firstLabel} , tRow ];
end

function s = strip_ext(fn)
[p,n,~] = fileparts(fn);
if isempty(p), s = n; else, s = n; end
end

function name = compose_filename(EEG, suffix, TS)
base = strip_ext(EEG.filename);
name = sprintf('%s_%s', base, suffix);
if TS
    name = sprintf('%s_%s', name, datestr(now,'mm_dd_yyyy-HHMM'));
end
end
