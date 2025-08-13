function [EEG, com] = pop_epochfile(EEG, TimeBased, StimCodes, Preonset, Postonset, BaselineCorrectStart, BaselineCorrectEnd, GUIOnOff)
% [EEG, com] = pop_epochfile(EEG, TimeBased, StimCodes, Preonset, Postonset, BaselineCorrectStart, BaselineCorrectEnd, GUIOnOff)
% Bundle of pop_epoch / eeg_regepochs (+ optional baseline correction).
%
% Inputs (programmatic):
%   TimeBased             - scalar (ms). If >0, create fixed-length epochs every TimeBased ms (continuous data).
%   StimCodes             - event codes to epoch around: string like '10 12', numeric array, or cellstr.
%   Preonset, Postonset   - ms relative to event onset (negative/positive).
%   BaselineCorrectStart  - ms (e.g., -100). Optional; if empty -> skip baseline.
%   BaselineCorrectEnd    - ms (e.g., 0). Optional.
%   GUIOnOff              - if true/nonzero, skip GUI; otherwise open GUI to gather inputs.
%
% Notes:
%   - For time-based epochs, baseline (if supplied) is applied relative to epoch start (0 ms).
%   - If EEG is already epoched and TimeBased>0, function errors (eeg_regepochs needs continuous).
%
% Author: Matthew Phillip Gunn (refreshed 2025-08-13)

com = '';
if nargin < 1 || isempty(EEG)
    error('pop_epochfile: EEG dataset is required.');
end

% ----------------------------
% GUI mode if args not provided or GUIOnOff not set
% ----------------------------
useGUI = (nargin < 8) || isempty(GUIOnOff) || ~GUIOnOff;
if useGUI
    % Geometry
    row = [.75 1 1];
    gl  = {};
    ui  = {};
    addrow = @(cells) (gl{end+1} = row); %#ok<AGROW>

    % Title
    gl{end+1} = 1;
    ui{end+1} = {'style','text','string','Epoch File — wrapper for pop_epoch / eeg_regepochs (+ baseline)','fontweight','bold'};

    % Time-based
    addrow(); ui = [ui, { ...
        {'style','text','string','Time-based interval (ms)'} ...
        {'style','edit','string',''} ...
        {'style','text','string','Ex: 1000 → epochs every 1000 ms (continuous only)'} ...
    }];

    % Stimulus-based
    gl{end+1} = 1; ui{end+1} = {'style','text','string','Stimulus-based','fontweight','bold'};
    addrow(); ui = [ui, { ...
        {'style','text','string','Stim codes'} ...
        {'style','edit','string',''} ...
        {'style','text','string','Ex: 10 12   or   S10,S12'} ...
    }];

    % Windows (ms)
    addrow(); ui = [ui, { ...
        {'style','text','string','Pre-onset (ms)'} ...
        {'style','edit','string','-200'} ...
        {'style','text','string','e.g., -200'} ...
    }];
    addrow(); ui = [ui, { ...
        {'style','text','string','Post-onset (ms)'} ...
        {'style','edit','string','800'} ...
        {'style','text','string','e.g., 800'} ...
    }];
    addrow(); ui = [ui, { ...
        {'style','text','string','Baseline start (ms)'} ...
        {'style','edit','string','-200'} ...
        {'style','text','string','leave blank to skip'} ...
    }];
    addrow(); ui = [ui, { ...
        {'style','text','string','Baseline end (ms)'} ...
        {'style','edit','string','0'} ...
        {'style','text','string','leave blank to skip'} ...
    }];

    res = inputgui(gl, ui, 'title', 'Script Creation — pop_epochfile()');
    if isempty(res), return; end

    % Parse GUI fields
    TimeBased = str2double(res{1});                      % ms
    stimStr   = strtrim(res{2});
    Preonset  = str2double(res{3});                     % ms
    Postonset = str2double(res{4});                     % ms

    if ~isempty(res{5}), BaselineCorrectStart = str2double(res{5}); else, BaselineCorrectStart = []; end
    if ~isempty(res{6}), BaselineCorrectEnd   = str2double(res{6}); else, BaselineCorrectEnd   = []; end

    if ~isempty(stimStr)
        StimCodes = parseStimCodes(stimStr);
    else
        StimCodes = {};
    end
else
    % Programmatic: ensure defaults exist
    if ~exist('TimeBased','var') || isempty(TimeBased), TimeBased = 0; end
    if ~exist('StimCodes','var') || isempty(StimCodes), StimCodes = {}; end
    if ischar(StimCodes) || isstring(StimCodes)
        StimCodes = parseStimCodes(string(StimCodes));
    end
    if ~exist('Preonset','var')  || isempty(Preonset),  Preonset  = -200; end
    if ~exist('Postonset','var') || isempty(Postonset), Postonset =  800; end
    if ~exist('BaselineCorrectStart','var'), BaselineCorrectStart = []; end
    if ~exist('BaselineCorrectEnd','var'),   BaselineCorrectEnd   = []; end
end

% Validate numeric fields
numchk = @(x, name) assert(isnumeric(x) && isscalar(x) && isfinite(x), 'pop_epochfile: %s must be a finite scalar.', name);
if ~isempty(TimeBased),           numchk(TimeBased, 'TimeBased (ms)'); end
if ~isempty(Preonset),            numchk(Preonset, 'Preonset (ms)'); end
if ~isempty(Postonset),           numchk(Postonset, 'Postonset (ms)'); end
if ~isempty(BaselineCorrectStart),numchk(BaselineCorrectStart, 'BaselineCorrectStart (ms)'); end
if ~isempty(BaselineCorrectEnd),  numchk(BaselineCorrectEnd, 'BaselineCorrectEnd (ms)'); end

% ----------------------------
% Execute
% ----------------------------
didTimeBased = ~isempty(TimeBased) && ~isnan(TimeBased) && TimeBased > 0;

if didTimeBased
    if EEG.trials > 1
        error('pop_epochfile: Time-based regepochs require continuous data (EEG.trials == 1).');
    end
    % Convert ms -> s, and set 0..T window
    Tsec = TimeBased / 1000;
    EEG  = eeg_regepochs(EEG, 'recurrence', Tsec, 'limits', [0 Tsec]);

    % Optional baseline relative to epoch start (0..T)
    if ~isempty(BaselineCorrectStart) && ~isempty(BaselineCorrectEnd)
        EEG = pop_rmbase(EEG, [BaselineCorrectStart BaselineCorrectEnd]);
    end

    % Build history
    if useGUI
        % store GUI choices in ms
        regions = {TimeBased, StimCodes, Preonset, Postonset, BaselineCorrectStart, BaselineCorrectEnd};
        com = sprintf('EEG = pop_epochfile(EEG, %s);', vararg2str(regions));
    else
        com = sprintf('EEG = eeg_regepochs(EEG, ''recurrence'', %g, ''limits'', [0 %g]);', Tsec, Tsec);
        if ~isempty(BaselineCorrectStart) && ~isempty(BaselineCorrectEnd)
            com = sprintf('%s EEG = pop_rmbase(EEG, [%g %g]);', com, BaselineCorrectStart, BaselineCorrectEnd);
        end
    end

else
    % Stimulus-based route
    if isempty(StimCodes)
        error('pop_epochfile: Provide StimCodes (or a positive TimeBased interval).');
    end
    winSec = [Preonset Postonset] / 1000;  % ms -> s
    EEG    = pop_epoch(EEG, StimCodes, winSec);

    if ~isempty(BaselineCorrectStart) && ~isempty(BaselineCorrectEnd)
        EEG = pop_rmbase(EEG, [BaselineCorrectStart BaselineCorrectEnd]);
    end

    % Build history
    if useGUI
        regions = {TimeBased, StimCodes, Preonset, Postonset, BaselineCorrectStart, BaselineCorrectEnd};
        com = sprintf('EEG = pop_epochfile(EEG, %s);', vararg2str(regions));
    else
        % Reconstruct StimCodes text for history (compact and readable)
        stimtxt = stimcodes2str(StimCodes);
        com = sprintf('EEG = pop_epoch(EEG, %s, [%g %g]);', stimtxt, winSec(1), winSec(2));
        if ~isempty(BaselineCorrectStart) && ~isempty(BaselineCorrectEnd)
            com = sprintf('%s EEG = pop_rmbase(EEG, [%g %g]);', com, BaselineCorrectStart, BaselineCorrectEnd);
        end
    end
end

end % main

% ----------------------------
% Helpers
% ----------------------------
function C = parseStimCodes(s)
% Accept '10 12', 'S10,S12', '10,S12' etc. -> {'10','12'} or numeric array if all numeric
if isstring(s), s = char(s); end
s = strrep(s, ',', ' ');
parts = strtrim(split(s));
parts = parts(~cellfun(@isempty, parts));
% Try numeric
vals = str2double(parts);
if all(~isnan(vals))
    C = num2cell(vals); % pop_epoch accepts numeric inside a cell
else
    C = cellstr(parts); % strings like 'S10'
end
end

function t = stimcodes2str(StimCodes)
% Produce readable text for history
if iscell(StimCodes)
    if isempty(StimCodes)
        t = '{}';
        return;
    end
    if isnumeric([StimCodes{:}])
        t = ['{' strjoin(arrayfun(@(x) num2str(x{1}), StimCodes, 'uni', false), ' ') '}'];
    else
        % quote strings
        q = cellfun(@(x) ['''' char(x) ''''], StimCodes, 'uni', false);
        t = ['{' strjoin(q, ' ') '}'];
    end
elseif isnumeric(StimCodes)
    t = ['{' strjoin(arrayfun(@(x) num2str(x), StimCodes, 'uni', false), ' ') '}'];
else
    % string
    t = ['{''' char(StimCodes) '''}'];
end
end
