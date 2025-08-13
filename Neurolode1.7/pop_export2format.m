function [EEG, com] = pop_export2format(EEG, CoI, GA, AC, TS, FileType)
% pop_export2format() - GUI wrapper to export EEG data to .xlsx/.dat/.txt
%                       via export2format.m
%
% Usage:
%   >> [EEG, com] = pop_export2format(EEG);
%   >> [EEG, com] = pop_export2format(EEG, '1:10', 1, 0, 1, '.xlsx');
%
% Inputs:
%   EEG      - EEGLAB dataset
%   CoI      - Channels of interest string, e.g. '1:10, 15, 20:22'
%   GA       - 1 = grand average over epochs; 0 otherwise
%   AC       - 1 = average the listed channels; 0 otherwise
%   TS       - 1 = append timestamp to output filename; 0 otherwise
%   FileType - one of {'.xlsx','.dat','.txt'} (default chosen in GUI)
%
% Output:
%   EEG, com - standard EEGLAB pattern (EEG unchanged here; com is history)
%
% Notes:
% - Delegates actual formatting/writing to export2format.m
% - Adds basic validation and a file-type dropdown in the GUI
% Author: Matthew Phillip Gunn
com = '';

% ----- sanity checks -----
if nargin < 1 || isempty(EEG)
    help pop_export2format; return;
end
if ~isfield(EEG,'data') || isempty(EEG.data)
    error('pop_export2format: EEG.data is empty.');
end
if ~isfield(EEG,'filename') || isempty(EEG.filename)
    error('pop_export2format: EEG.filename is empty. Save your dataset first.');
end

% build a safe base name (strip extension if present)
[~, baseName, ~] = fileparts(EEG.filename);

% ----- collect inputs via GUI if needed -----
if nargin < 6 || isempty(CoI) || isempty(GA) || isempty(AC) || isempty(TS) || isempty(FileType)
    NumberOfFieldsAndFieldSpace = [.75 1 1];

    Title = { { 'style' 'text' 'string' 'Export data to file' 'fontweight' 'bold' } ...
              {} { 'style' 'text' 'string' '' } { 'style' 'text' 'string' '' } };

    C1   = { { 'style' 'text' 'string' 'Channels of interest' } ...
             { 'style' 'edit' 'string' '1:10' } ...
             { 'style' 'text' 'string' 'e.g., 1:10  or  1:4,7,10:12' } };

    Mo1  = { { 'style' 'text' 'string' 'Grand average epochs' } ...
             { 'style' 'checkbox' 'string' '' } ...
             { 'style' 'text' 'string' 'Average across epochs (GA)' } };

    Mo2  = { { 'style' 'text' 'string' 'Average channels' } ...
             { 'style' 'checkbox' 'string' '' } ...
             { 'style' 'text' 'string' 'Average selected channels (AC)' } };

    Mo4  = { { 'style' 'text' 'string' 'Timestamp filenames' } ...
             { 'style' 'checkbox' 'string' '' } ...
             { 'style' 'text' 'string' 'Append datetime to filename (TS)' } };

    FT   = { { 'style' 'text' 'string' 'File type' } ...
             { 'style' 'popupmenu' 'string' '.xlsx|.dat|.txt' 'value' 1 } ...
             { 'style' 'text' 'string' 'Choose export format' } };

    allGeom = { 1 NumberOfFieldsAndFieldSpace };
    Title   = [ Title(:)' C1(:)'];   allGeom{end+1} = NumberOfFieldsAndFieldSpace;
    Title   = [ Title(:)' Mo1(:)'];  allGeom{end+1} = NumberOfFieldsAndFieldSpace;
    Title   = [ Title(:)' Mo2(:)'];  allGeom{end+1} = NumberOfFieldsAndFieldSpace;
    Title   = [ Title(:)' Mo4(:)'];  allGeom{end+1} = NumberOfFieldsAndFieldSpace;
    Title   = [ Title(:)' FT(:)'];   allGeom{end+1} = NumberOfFieldsAndFieldSpace;

    res = inputgui(allGeom, Title);
    if isempty(res), return; end

    CoI = res{1};                      % string like '1:10, 15'
    GA  = logical(res{2});
    AC  = logical(res{3});
    TS  = logical(res{4});
    ftIdx = res{5};
    ftOpts = {'.xlsx','.dat','.txt'};
    FileType = ftOpts{ftIdx};
else
    % ensure scalar logicals
    GA = logical(GA); AC = logical(AC); TS = logical(TS);
end

% ----- normalize CoI to a string -----
if iscell(CoI), CoI = CoI{1}; end
if ~ischar(CoI) && ~isstring(CoI)
    error('pop_export2format: CoI must be a channel list string.');
end
CoI = char(CoI); % export2format expects a string it can parse

% ----- one more filename check (rare edge case) -----
if isempty(baseName)
    error('pop_export2format: Could not derive a base filename. Save your dataset first.');
end

% ----- call worker -----
try
    EEG = export2format(EEG, CoI, GA, AC, TS, FileType);
catch ME
    % Provide clearer guidance if Excel writing fails
    if strcmpi(FileType,'.xlsx')
        warning('pop_export2format: XLSX write failed (%s). Try .dat or .txt instead.', ME.message);
    end
    rethrow(ME);
end

% ----- history string -----
regions = {CoI, GA, AC, TS, FileType};
com = sprintf('EEG = export2format(EEG,%s);', vararg2str(regions));
end
