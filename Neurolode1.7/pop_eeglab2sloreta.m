function [EEG, com] = pop_eeglab2sloreta(EEG, ListSort, BadChan, GUIOnOff)
% pop_eeglab2sloreta  Prepare/export EEGLAB data for sLORETA.
%
% Usage:
%   >> [EEG, com] = pop_eeglab2sloreta(EEG);                  % GUI
%   >> [EEG, com] = pop_eeglab2sloreta(EEG, '8:10', [], 1);   % programmatic
%   >> [EEG, com] = pop_eeglab2sloreta(EEG, 'subspan', [1 3 7], 1);
%
% Inputs
%   EEG      : EEGLAB dataset
%   ListSort : either a span string like '8:10' (characters of filename
%              used to create subfolders) OR any string you want passed to
%              eeglab2sloreta() for its own sorting logic. Optional in GUI.
%   BadChan  : numeric vector of channels to remove BEFORE export. [] or 0
%              to keep all channels.
%   GUIOnOff : 0/empty → show GUI, 1 → no GUI (use args)
%
% Outputs
%   EEG, com : updated dataset (if channels removed) and EEGLAB history cmd
%
% Notes
% - The actual formatting/export is performed by eeglab2sloreta(EEG, ListSort, BadChan).
% - This wrapper only collects inputs and (optionally) removes channels

% Copyright (C) 2021  Matthew Gunn, neurolode@gmail
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

com = '';
if nargin < 1 || isempty(EEG)
    error('pop_eeglab2sloreta: EEG dataset is required.');
end

% Decide GUI vs programmatic
useGUI = (nargin < 4) || isempty(GUIOnOff) || ~GUIOnOff;

if useGUI
    % ---- GUI ----
    row = [.75 1 1];
    geom = {1, row, row};
    uilist = { ...
        { 'style' 'text'  'string' 'Export To sLORETA' 'fontweight' 'bold' } ...
        { 'style' 'text'  'string' 'Characters to sort on (e.g., 8:10)' } ...
        { 'style' 'edit'  'string' '' } ...
        { 'style' 'text'  'string' 'Remove channels?' } ...
        { 'style' 'checkbox' 'string' '' } ...
    };

    res = inputgui(geom, uilist, 'title', 'Export To sLORETA — pop_eeglab2sloreta()');
    if isempty(res), return; end
    ListSort = strtrim(res{1});
    wantRemove = logical(res{2});

    % Channel‑removal dialog if requested
    if wantRemove
        [BadChan, ok] = choose_bad_channels(EEG);
        if ~ok, return; end
    else
        BadChan = [];
    end
else
    % ---- programmatic ----
    if nargin < 2 || isempty(ListSort), ListSort = ''; end
    if nargin < 3 || isempty(BadChan) || isequal(BadChan,0), BadChan = []; end
end

% If there are bad channels, remove before export (keeps worker simple)
if ~isempty(BadChan)
    EEG = pop_select(EEG, 'nochannel', BadChan);
end

% Call your underlying worker (unchanged behavior)
EEG = eeglab2sloreta(EEG, ListSort, BadChan);

% Build history command
if useGUI
    % Preserve GUI args in history (channels inline)
    regions = {ListSort, BadChan};
    com = sprintf('EEG = eeglab2sloreta(EEG, %s);', vararg2str(regions));
else
    % Programmatic — mirror call succinctly
    if isempty(BadChan)
        com = sprintf('EEG = eeglab2sloreta(EEG, ''%s'', []);', ListSort);
    else
        badStr = sprintf('%s', mat2str(BadChan));
        com = sprintf('EEG = eeglab2sloreta(EEG, ''%s'', %s);', ListSort, badStr);
    end
end

end % ====== main ======

% ---------------- helpers ----------------

function [badIdx, ok] = choose_bad_channels(EEG)
% Simple list dialog over labels; returns numeric indices
ok = false; badIdx = [];
if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs)
    warndlg('No channel locations/labels available to choose from.','Remove channels'); 
    return;
end
labels = string({EEG.chanlocs.labels});
[listIdx, ok] = listdlg( ...
    'PromptString','Select channels to remove:', ...
    'SelectionMode','multiple', ...
    'ListString', cellstr(labels), ...
    'ListSize',[300 400], ...
    'Name','Remove channels');
if ~ok, return; end
badIdx = listIdx(:).';
ok = true;
end