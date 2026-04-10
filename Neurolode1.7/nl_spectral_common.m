function varargout = nl_spectral_common(action, varargin)
% nl_spectral_common
% Shared helper utilities for Neurolode spectral pop_* functions.
%
% This helper is internal and intended to preserve legacy behavior while
% reducing duplicated local helper code across functions.

switch lower(action)
    case 'resolve_coi'
        varargout{1} = resolve_coi(varargin{1}, varargin{2});
    case 'chan_label'
        varargout{1} = chan_label(varargin{1}, varargin{2});
    case 'coi_for_history'
        varargout{1} = coi_for_history(varargin{1});
    case 'strip_ext'
        varargout{1} = strip_ext(varargin{1});
    case 'iff'
        varargout{1} = iff(varargin{1}, varargin{2}, varargin{3});
    case 'avg_label'
        varargout{1} = avg_label(varargin{1});
    otherwise
        error('nl_spectral_common:UnknownAction', 'Unknown action: %s', string(action));
end

end

function idx = resolve_coi(COIraw, EEG)
if isnumeric(COIraw)
    idx = COIraw(:).';
    return;
end
if iscell(COIraw)
    idx = labels2idx(string(COIraw(:)), EEG);
    return;
end
s = string(COIraw);
s = strrep(s, ',', ' ');
parts = strtrim(split(strtrim(s)));
idx = [];
for i = 1:numel(parts)
    tok = parts{i};
    if isempty(tok), continue; end
    r = regexp(tok, '^(\d+)\s*[-:]\s*(\d+)$', 'tokens', 'once');
    if ~isempty(r)
        a = str2double(r{1});
        b = str2double(r{2});
        idx = [idx, a:sign(b-a):b]; %#ok<AGROW>
        continue;
    end
    v = str2double(tok);
    if ~isnan(v)
        idx = [idx, v]; %#ok<AGROW>
        continue;
    end
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

function lab = avg_label(chanIdx)
lab = sprintf('AvgChans_%s', strjoin(string(chanIdx),'_'));
end
