function pop_functionsettings(gca_in, gco_in)
% pop_functionsettings(gca,gco) - Show/edit the function call behind a button
%
% Keeps the same calling style from your callback:
%   'callback', ['pop_functionsettings(gca,gco)']

% Fetch UI state
% Author: Matthew Phillip Gunn
ud = get(get(gca_in,'Parent'),'userdata');
if isempty(ud) || ~isfield(ud,'OrderName') || ~isfield(ud,'OrderNum') || ~isfield(ud,'Operation')
    warning('AutoBatch: No userdata found on parent figure.'); return;
end

% Identify which operation this button represents
btnTag = get(gco_in,'tag');
idx = find(contains(string(ud.OrderName), btnTag), 1, 'first');
if isempty(idx)
    warning('AutoBatch: Could not map button to an operation.'); return;
end

opIdx = ud.OrderNum{idx,1};
if opIdx<1 || opIdx>numel(ud.Operation)
    warning('AutoBatch: Invalid operation index.'); return;
end

% Current operation string (as char)
CurrOper = ud.Operation{opIdx,1};
if isstring(CurrOper), CurrOper = char(CurrOper); end

% Parse "name(args...)" from a typical EEGLAB history line: "EEG = func(arg1,...);"
eqPos = strfind(CurrOper, '=');
lpPos = strfind(CurrOper, '(');
rpPos = strfind(CurrOper, ')');

ProcessHolder = 'UnknownFunction';
OperArgsStr   = '';

if ~isempty(eqPos) && ~isempty(lpPos)
    % prefer the first '(' after '=' if both exist
    temp = CurrOper;
    eq  = eqPos(1);
    lp  = lpPos(1);
    if eq < lp
        ProcessHolder = strtrim(temp(eq+1:lp-1));
    end
end
if ~isempty(lpPos) && ~isempty(rpPos)
    lp = lpPos(end);               % last '(' (handles nested pairs poorly but typical eegh is flat)
    rp = rpPos(end);               % last ')'
    if lp < rp
        OperArgsStr = strtrim(CurrOper(lp+1:rp-1));
    end
end

% Pull out name/value-ish pairs appearing as  'name', value  (very common in EEGLAB)
% This is best-effort; we won’t try to fully parse nested cells/structs.
VarListName  = {};
VarListInput = {};
if ~isempty(OperArgsStr)
    % tokenize at commas but keep quoted chunks intact
    tokens = regexp(OperArgsStr, ',(?=(?:[^'']*''[^'']*'')*[^'']*$)', 'split');
    i = 1;
    while i <= numel(tokens)
        tok = strtrim(tokens{i});
        % if token starts with quote, treat as a name and pair with next token if any
        if ~isempty(tok) && tok(1) == ''''
            VarListName{end+1,1}  = tok; %#ok<AGROW>
            if i+1 <= numel(tokens)
                VarListInput{end+1,1} = strtrim(tokens{i+1}); %#ok<AGROW>
                i = i + 2;
            else
                VarListInput{end+1,1} = ''; %#ok<AGROW>
                i = i + 1;
            end
        else
            % skip positional or unquoted args
            i = i + 1;
        end
    end
end

% Build GUI
Ti = sprintf('AutoBatch Function Settings: %s', ProcessHolder);
rows = max(1, numel(VarListName));
geom = cell(1, rows + 5);  % each pair row + headers/edits
uil  = {};

% Header
geom{1} = [1];
uil{end+1} = { 'Style','text','string',Ti,'fontweight','bold' };

% Pairs (read-only recap)
if ~isempty(VarListName)
    for k = 1:numel(VarListName)
        geom{end+1} = [1 1];
        uil{end+1} = { 'Style','text','string', VarListName{k}, 'fontweight','bold' };
        uil{end+1} = { 'Style','text','string', VarListInput{k} };
    end
else
    geom{end+1} = [1];
    uil{end+1}  = { 'Style','text','string','(No ''name'', value pairs detected in this call.)' };
end

% Originals / Editable
geom{end+1} = [1];
uil{end+1}  = { 'Style','text','string','Original','fontweight','bold' };

geom{end+1} = [1];
uil{end+1}  = { 'Style','text','string', CurrOper };

geom{end+1} = [1];
uil{end+1}  = { 'Style','text','string','Editable','fontweight','bold' };

geom{end+1} = [1];
uil{end+1}  = { 'Style','edit','string', CurrOper };

geom{end+1} = [1];
uil{end+1}  = { 'Style','checkbox','string','Save changes','value',0,'fontweight','bold' };

% Pack and show
[res, ud_out] = inputgui('geometry', geom, 'uilist', uil, ...
    'helpcom','pophelp(''pop_chanedit'');', 'title', Ti, 'userdata', ud); %#ok<ASGLU>

% res is a cell array of values for editable controls: {editString, saveCheckbox}
% Given our layout, the only edit control is the editable op string, and the only checkbox is "Save changes".
if isempty(res), return; end

newOp = res{1};
saveFlag = false;
if numel(res) >= 2
    saveFlag = logical(res{2});
end

% Apply change
if saveFlag
    if ~ischar(newOp) && ~isstring(newOp)
        warning('AutoBatch: Edited operation must be text. Change ignored.');
        return;
    end
    newOp = char(newOp);
    ud = get(get(gca_in,'Parent'),'userdata');    % re-fetch in case it changed
    if opIdx>=1 && opIdx<=numel(ud.Operation)
        ud.Operation{opIdx,1} = newOp;
        set(get(gca_in,'Parent'),'userdata', ud);
    else
        warning('AutoBatch: Operation index vanished; unable to save changes.');
    end
end
end
