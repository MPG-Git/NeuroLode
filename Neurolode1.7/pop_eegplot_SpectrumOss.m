function com = pop_eegplot(EEG, icacomp, superpose, reject, topcommand, varargin)
% pop_eegplot() - Visually inspect EEG (channels or ICs) with scrolling display.
%                 Mark or reject stretches of continuous data or entire epochs.
%
% Usage:
%   >> pop_eegplot(EEG);                        % default: channels, show new marks, mark-only
%   >> pop_eegplot(EEG, icacomp, superpose, reject, topcommand, ...)
%
% Inputs:
%   EEG        - EEGLAB dataset
%   icacomp    - 1: channels (default), 0: ICs (requires ICA present)
%   superpose  - (kept for compatibility) show previous visual marks (epochs only)
%   reject     - 0: mark only (default for continuous); 1: enable direct rejection
%   topcommand - deprecated, kept for compatibility
%   varargin   - extra name/value pairs passed to eegplot
%
% Notes:
% - For IC mode, ICA must exist (icasphere/icaweights not empty).
% - For continuous data, pressing "REJECT" calls eeg_eegrej() and creates a new dataset.
% - For epoched data, use the "Update Marks" / "Reject" workflow in the eegplot GUI.
% Author: Matthew Phillip Gunn
% Author (orig.): Arnaud Delorme


com = '';
if nargin < 1 || isempty(EEG)
    help pop_eegplot; return;
end

% ---------- defaults ----------
if nargin < 2 || isempty(icacomp),  icacomp  = 1; end
if nargin < 3 || isempty(superpose), superpose = 0; end
if nargin < 4 || isempty(reject),    reject   = 1; end
if nargin < 5,                        topcommand = []; end %#ok<NASGU>

% ---------- quick checks ----------
if icacomp == 0
    if ~isfield(EEG,'icasphere') || isempty(EEG.icasphere) || ...
       ~isfield(EEG,'icaweights') || isempty(EEG.icaweights)
        error('pop_eegplot: ICA not found. Run ICA first or set icacomp=1.');
    end
end
if ~isfield(EEG,'srate') || isempty(EEG.srate) || EEG.srate <= 0
    error('pop_eegplot: EEG.srate must be positive.');
end

% ---------- GUI for epoch data (legacy behavior) ----------
if (nargin < 3) && EEG.trials > 1
    uilist = { ...
        { 'style' 'text'    'string' 'Add to previously marked rejections? (checked = yes)'} ...
        { 'style' 'checkbox' 'string' '' 'value' 1 } ...
        { 'style' 'text'    'string' 'Reject marked trials? (checked = yes)'} ...
        { 'style' 'checkbox' 'string' '' 'value' 0 } ...
    };
    res = inputgui({[2 0.2] [2 0.2]}, uilist, 'pophelp(''pop_eegplot'');', ...
        fastif(icacomp==0,'Manual component rejection -- pop_eegplot()', ...
                        'Reject epochs by visual inspection -- pop_eegplot()'));
    if isempty(res), return; end
    if res{1}, superpose = 1; end
    if ~res{2}, reject = 0; end
end

% ---------- build eegplot options ----------
eegplotoptions = {};
if isfield(EEG,'event') && ~isempty(EEG.event)
    eegplotoptions = [eegplotoptions, {'events', EEG.event}]; %#ok<AGROW>
end
if ~isempty(EEG.chanlocs) && icacomp==1
    eegplotoptions = [eegplotoptions, {'eloc_file', EEG.chanlocs}]; %#ok<AGROW>
end

% speed hint for big montages
if EEG.nbchan > 100
    disp('pop_eegplot(): Large montage detected; disabling baseline subtraction to speed up display.');
    eegplotoptions = [eegplotoptions, {'submean','off'}]; %#ok<AGROW>
end

% ---------- epoch path (leverages EEGLAB rejection arrays) ----------
if EEG.trials > 1
    % Determine which rejection arrays to use
    if icacomp == 1
        macrorej  = 'EEG.reject.rejmanual';
        macrorejE = 'EEG.reject.rejmanualE';
        elecrange = 1:EEG.nbchan;
    else
        macrorej  = 'EEG.reject.icarejmanual';
        macrorejE = 'EEG.reject.icarejmanualE';
        elecrange = 1:size(EEG.icaweights,1);
    end

    % Ensure fields exist to avoid eval errors
    if ~isfield(EEG,'reject') || isempty(EEG.reject)
        EEG.reject = struct(); 
    end
    if ~isfield(EEG.reject,'rejmanual')     , EEG.reject.rejmanual     = false(1,EEG.trials); end
    if ~isfield(EEG.reject,'rejmanualE')    , EEG.reject.rejmanualE    = false(EEG.nbchan,EEG.trials); end
    if ~isfield(EEG.reject,'icarejmanual')  , EEG.reject.icarejmanual  = false(1,EEG.trials); end
    if ~isfield(EEG.reject,'icarejmanualE') , EEG.reject.icarejmanualE = false(size(elecrange,2),EEG.trials); end
    if ~isfield(EEG.reject,'rejmanualcol')  , EEG.reject.rejmanualcol  = [1 0.6 0.6]; end

    colrej = EEG.reject.rejmanualcol; %#ok<NASGU>
    rej    = eval(macrorej);          %#ok<NASGU>
    rejE   = eval(macrorejE);         %#ok<NASGU>

    % Use eeg_rejmacro to prepare command + previous marks overlay
    eeg_rejmacro; % defines 'command' and uses macro variables above

    % Fire up eegplot on channels vs ICs
    if icacomp == 1
        eegplot(EEG.data, 'srate', EEG.srate, ...
            'title', ['Scroll channel activities -- eegplot() -- ' EEG.setname], ...
            'limits', [EEG.xmin EEG.xmax]*1000, ...
            'superpose', superpose, 'reject', reject, ...
            eegplotoptions{:}, varargin{:});
    else
        tmpdata = eeg_getdatact(EEG, 'component', elecrange);
        eegplot(tmpdata, 'srate', EEG.srate, ...
            'title', ['Scroll component activities -- eegplot() -- ' EEG.setname], ...
            'limits', [EEG.xmin EEG.xmax]*1000, ...
            'superpose', superpose, 'reject', reject, ...
            eegplotoptions{:}, varargin{:});
    end

    com = sprintf('pop_eegplot(EEG, %d, %d, %d);', icacomp, superpose, reject);
    return;
end

% ---------- continuous path ----------
% Build the command executed when user presses REJECT in eegplot
if reject == 0
    command = ''; % mark only (no dataset modification from this window)
else
    if nargin < 4
        res = questdlg2( strvcat( ...
            'Mark stretches of continuous data for rejection by dragging the left mouse button.', ...
            'Click on a marked stretch to unmark. When done, press "REJECT" to excise marked', ...
            'stretches (Note: boundary markers are kept in the event table).'), ...
            'Warning', 'Cancel', 'Continue', 'Continue');
        if strcmpi(res,'Cancel'), return; end
    end
    command = [ ...
        '[EEGTMP LASTCOM] = eeg_eegrej(EEG, eegplot2event(TMPREJ, -1));' ...
        'if ~isempty(LASTCOM),' ...
        '  [ALLEEG EEG CURRENTSET tmpcom] = pop_newset(ALLEEG, EEGTMP, CURRENTSET);' ...
        '  if ~isempty(tmpcom),' ...
        '     EEG = eegh(LASTCOM, EEG);' ...
        '     eegh(tmpcom);' ...
        '     eeglab(''redraw'');' ...
        '  end;' ...
        'end;' ...
        'clear EEGTMP tmpcom;' ];
end

% Select data to plot: channels vs ICs
if icacomp == 1
    plotdata = EEG.data;
    ttl = ['Scroll channel activities -- eegplot() -- ' EEG.setname];
else
    plotdata = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights,1));
    ttl = ['Scroll component activities -- eegplot() -- ' EEG.setname];
end

eegplot(plotdata, ...
    'srate', EEG.srate, ...
    'title', ttl, ...
    'limits', [EEG.xmin EEG.xmax]*1000, ...
    'command', command, ...
    eegplotoptions{:}, varargin{:});

com = sprintf('pop_eegplot(EEG, %d, %d, %d);', icacomp, superpose, reject);
end
