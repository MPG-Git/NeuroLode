% [EEG, com] = eeglab2sloreta( EEG,ListSort,BadChanGUI,GUIOnOff)
%                  - This formats data for use in sLORETA.
%
% Usage:
%   >>  OUTEEG = eeglab2sloreta( EEG,ListSort,BadChanGUI)
% 
%
% Inputs:
%   EEG         - Input dataset.
%   ListSort    - The chacters in the filename to sort into folders.
%   BadChanGUI  - Channels that should be removed from dataset.
%    
% Outputs:
%   OUTEEG     - Output dataset.
%
% Author: Matthew Phillip Gunn 
%
% See also: 
%   pop_select, pop_export, eeglab 

% Copyright (C) 2021  Matthew Gunn, Southern Illinois University Carbondale, neurolode@gmail
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.
function EEG = eeglab2sloreta(EEG, ListSort, BadChan)
% ---- sanity checks ----
if nargin < 1 || isempty(EEG)
    error('eeglab2sloreta: EEG dataset required.');
end
if nargin < 2, ListSort = ''; end
if nargin < 3 || isempty(BadChan) || isequal(BadChan,0), BadChan = []; end

% ---- remove bad channels (if any) ----
if ~isempty(BadChan)
    EEG = pop_select(EEG, 'nochannel', BadChan);
end

% ---- decide output subfolder name ----
baseName = strip_ext(EEG.filename);         % filename without extension
outFolderName = '';

% If ListSort looks like "start:end", take that slice of EEG.filename
span = regexp(strtrim(char(string(ListSort))), '^\s*(\d+)\s*:\s*(\d+)\s*$', 'tokens', 'once');
if ~isempty(span)
    s = str2double(span{1});
    e = str2double(span{2});
    if isnan(s) || isnan(e) || s < 1 || e > numel(EEG.filename) || s > e
        error('eeglab2sloreta: invalid ListSort span "%s" for filename "%s".', ListSort, EEG.filename);
    end
    outFolderName = EEG.filename(s:e);
else
    % treat ListSort as literal folder name (may be empty)
    outFolderName = strtrim(char(string(ListSort)));
    if isempty(outFolderName)
        outFolderName = baseName; % fallback
    end
end

% ---- create output folder (relative to current working dir) ----
outDir = fullfile(pwd, outFolderName);
if ~exist(outDir, 'dir')
    ok = mkdir(outDir);
    if ~ok, error('eeglab2sloreta: cannot create output directory: %s', outDir); end
end

% ---- prepare export ----
NewFilename = baseName;   % for file stems
nTr = max(1, EEG.trials);

% For export, we may need a single‑trial struct
EEG1 = EEG;
EEG1.trials = 1;

for j = 1:nTr
    if EEG.trials > 1
        EEG1.data  = EEG.data(:,:,j);
        % Optionally adjust events per epoch if needed; sLORETA ASCII
        % doesn’t include events, so we skip that complexity here.
        suffix = sprintf('%d', j);
    else
        EEG1.data  = EEG.data;
        suffix = '';
    end
    outFile = fullfile(outDir, [NewFilename suffix '.asc']);

    % Use EEGLAB exporter: channels-as-rows (transpose=on), no elec/time cols
    try
        pop_export(EEG1, outFile, 'transpose', 'on', 'elec', 'off', 'time', 'off');
    catch ME
        error('eeglab2sloreta: export failed for "%s": %s', outFile, ME.message);
    end
end

% Done. EEG returned (possibly with channels removed).
end

% ---------- helpers ----------
function s = strip_ext(fn)
[~, s, ~] = fileparts(fn);
end