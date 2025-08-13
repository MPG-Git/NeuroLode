function [EEG, com] = pop_AutoBatch(EEG, Record)
% pop_AutoBatch(EEG,Record)
% Build a batchable script from EEGLAB command history.
%
% Usage:
%   >> [EEG, com] = pop_AutoBatch(EEG);            % open main GUI
%   >> [EEG, com] = pop_AutoBatch(EEG, 1);         % internal: called on Stop
%
% Notes:
% - Click "Start Recording" to snapshot ALLCOM, perform steps, then "Stop Recording".
% - Reorder/remove steps, then "Save and Open AutoBatch Script".
%
% Author: Matthew Phillip Gunn. Refactor: 2025-08-13.

com = '';

% ---------- Handle inputs safely ----------
if nargin < 1 || isempty(EEG)
    EEG = evalin('base','EEG'); % best-effort for interactive use
end
haveRecordFlag = (nargin >= 2) && ~isempty(Record);

% ---------- Recover GUI state if called from a callback ----------
% We prefer gcbf (callback figure), then current figure if it is our GUI.
hFig = [];
if ~isempty(gcbf) && isvalid(gcbf), hFig = gcbf; end
if isempty(hFig) && ~isempty(get(0,'CurrentFigure'))
    hCand = get(0,'CurrentFigure');
    if isappdata(hCand,'AutoBatch_isGUI'), hFig = hCand; end
end

% ---------- Init / update history snapshots ----------
Starting_EEGH = [];
New_EEGH      = [];

if haveRecordFlag && ~isempty(hFig) && isvalid(hFig)
    % We just clicked "Stop Recording"; pull userdata set earlier.
    userdata = get(hFig, 'userdata');
    if isfield(userdata,'Starting_EEGH') && ~isempty(userdata.Starting_EEGH)
        Starting_EEGH = userdata.Starting_EEGH;
    end
    if isfield(userdata,'New_EEGH') && ~isempty(userdata.New_EEGH)
        New_EEGH = userdata.New_EEGH;
    end
else
    % Fresh open or "Start Recording" pressed
    Starting_EEGH = [];
    New_EEGH      = [];
end

% ---------- Build list of processes since Start ----------
% ALLCOM is a cellstr of command strings in recent EEGLABs
% Normalize both to cell arrays of char for robust diffing.
if isstring(Starting_EEGH), Starting_EEGH = cellstr(Starting_EEGH); end
if isstring(New_EEGH),      New_EEGH      = cellstr(New_EEGH);      end

if isempty(New_EEGH)
    AllProcesses = {};
else
    nStart = numel(Starting_EEGH);
    nNew   = numel(New_EEGH);
    span   = max(0, nNew - nStart);
    if span > 0
        AllProcesses = New_EEGH((nNew - span + 1):nNew);
    else
        AllProcesses = {};
    end
    % You had flip() to reverse; preserve it:
    AllProcesses = flip(AllProcesses);
end

% ---------- Build dynamic UI blocks ----------
CreateUIu = {};
CreateUIg = {};
TempidxN  = {};
Operation  = {};
OrderTrackerUI = {};

for k = 1:numel(AllProcesses)
    thisCom = AllProcesses{k};
    Operation{end+1,1} = thisCom; %#ok<AGROW>

    % Extract a "process name" to use as the header button title
    % Try to parse the LHS function name from "EEG = pop_xxx(...);"
    procLabel = parseProcessLabel(thisCom);

    % Header button (function label)
    tagFun = sprintf('UI_idxFun_%d', k);
    TempidxN{end+1,1} = tagFun; %#ok<AGROW>
    OrderTrackerUI{end+1,1} = k; %#ok<AGROW>

    % Row geometry for header
    CreateUIg{end+1} = 1; %#ok<AGROW>
    CreateUIu{end+1} = { ...
        'Style','pushbutton','string',procLabel,'fontweight','bold', ...
        'tag',tagFun, 'callback','pop_functionsettings(gca,gco)' ...
    }; %#ok<AGROW>

    % Row of control buttons (Down / Remove / Up)
    tagDown = sprintf('UI_idxDow_%d', k);
    tagRem  = sprintf('UI_idxRem_%d', k);
    tagUp   = sprintf('UI_idxUpB_%d', k);

    TempidxN{end+1,1} = tagDown; %#ok<AGROW>
    OrderTrackerUI{end+1,1} = k; %#ok<AGROW>
    TempidxN{end+1,1} = tagRem;  %#ok<AGROW>
    OrderTrackerUI{end+1,1} = k; %#ok<AGROW>
    TempidxN{end+1,1} = tagUp;   %#ok<AGROW>
    OrderTrackerUI{end+1,1} = k; %#ok<AGROW>

    CreateUIg{end+1} = [0.7 0.7 0.7]; %#ok<AGROW>
    CreateUIu{end+1} = { ...
        {'Style','pushbutton','string','Down','tag',tagDown, ...
            'callback','pop_MoveButton(gca,gco)'} ...
        {'Style','pushbutton','string','Remove','tag',tagRem, ...
            'callback','pop_RemoveButton(gca,gco)'} ...
        {'Style','pushbutton','string','Up','tag',tagUp, ...
            'callback','pop_MoveButton(gca,gco)'} ...
    }; %#ok<AGROW>
end

% ---------- Static UI bits ----------
Ti = 'Auto Batch Script';

ButtonSection = { ...
    {'Style','text','string',''} ...
    {'Style','text','string',''} ...
    {'Style','text','string',''} ...
};

StartAndStopRecorder = { ...
    {'Style','pushbutton','string','Start Recording', ...
        'callback', [ ...
        'userdata=get(get(gcbo,''Parent''),''userdata'');' ...
        'if isempty(userdata), userdata=struct; end; ' ...
        'userdata.Starting_EEGH=ALLCOM; ' ...
        'set(get(gcbo,''Parent''),''userdata'',userdata);' ...
        ]} ...
    {'Style','pushbutton','string','Stop Recording', ...
        'callback', [ ...
        'userdata=get(get(gcbo,''Parent''),''userdata'');' ...
        'if isempty(userdata), userdata=struct; end; ' ...
        'userdata.New_EEGH=ALLCOM; ' ...
        'set(get(gcbo,''Parent''),''userdata'',userdata);' ...
        'pop_AutoBatch(EEG,1);' ...
        ]} ...
};

% Geometry: flatten sub-rows from CreateUIu that are cell-of-cells
geom = { ...
    [1 .5 .5] ...
    1 ...
    [0.7 1 0.7] ...
    1 ...
    CreateUIg{:} ...
    1 1 1 ...
    [0.7 0.7] ...
    .5 ...
    1 ...
};

uiList = { ...
    {'Style','text','string',Ti,'fontweight','bold'}, {}, {} ...
    {'Style','text','string','Suggestions: Remove "pop_newset", "eeg_store", "pop_loadset", "pop_saveset", "eeg_checkset" from the batch.'} ...
    ButtonSection{:} ...
    {} ...
    CreateUIu{:} ...
    {} ...
    {} ...
    {} ...
    StartAndStopRecorder{:} ...
    {'Style','pushbutton','string','Open EEGLAB (no wipe)', 'callback','eeglab redraw'} ...
    {'Style','pushbutton','string','Save and Open AutoBatch Script','callback','pop_SaveNopen(gca,gco)'} ...
};

% ---------- Launch GUI ----------
userdata = struct;
userdata.OrderName        = TempidxN;
userdata.OrderNum         = OrderTrackerUI;
userdata.UpDownButtonRun  = 0;
userdata.Operation        = iff(haveRecordFlag, Operation, {});
setappdata(0,'AutoBatch_lastUserdata',userdata); % optional debug breadcrumb

[results, userdata, returnmode, hFigOut] = inputgui( ...
    'geometry', geom, ...
    'uilist', uiList, ...
    'helpcom', 'pophelp(''pop_AutoBatch'');', ...
    'title',  'Script Creation -- pop_AutoBatch()', ...
    'userdata', userdata);

if ~isempty(hFigOut) && isvalid(hFigOut)
    setappdata(hFigOut,'AutoBatch_isGUI',true); % tag figure so callbacks can find it safely
end

% No change to EEG here; this pop only orchestrates GUI/state
% Return a history stub for EEGLAB's command log
com = 'pop_AutoBatch(EEG);';

end  % --- main function end ---

% ---------- helpers ----------
function out = parseProcessLabel(cmd)
% Try to make a readable label from a command line like: "EEG = pop_xxx(EEG, ...);"
out = 'Process';
try
    % Prefer LHS function name after '=' then before '('
    % e.g., "EEG = pop_runica(EEG, 'pca', 30);"
    tok = regexp(cmd, '=\s*([a-zA-Z]\w*)\s*\(', 'tokens','once');
    if ~isempty(tok)
        out = tok{1};
        return;
    end
    % Fallback: any "pop_*(" occurrence
    tok = regexp(cmd, '(pop_[a-zA-Z]\w*)\s*\(', 'tokens','once');
    if ~isempty(tok)
        out = tok{1};
        return;
    end
    % Last resort: first word before '('
    tok = regexp(cmd, '^\s*([a-zA-Z]\w*)\s*\(', 'tokens','once');
    if ~isempty(tok)
        out = tok{1};
        return;
    end
catch
    % keep default
end
end

function out = iff(cond, a, b)
if cond, out = a; else, out = b; end
end
