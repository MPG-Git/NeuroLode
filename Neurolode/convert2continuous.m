function [EEG, com] = convert2continuous(EEG)
% convert2continuous  Flatten epoched EEG into a single continuous run.
%
% Usage:
%   >> [EEG, com] = convert2continuous(EEG);
%
% Notes:
% - Event latencies are converted from (epoch, within-epoch) to continuous samples.
% - Removes EEG.epoch and sets EEG.trials = 1.
%
% Author: Matthew Phillip Gunn (refreshed 2025-08-13)

com = 'convert2continuous(EEG);';

if nargin < 1 || isempty(EEG)
    error('convert2continuous: EEG dataset is required.');
end

% Already continuous? No-op
if EEG.trials <= 1
    return;
end

% --- Shapes ---
nChan = size(EEG.data, 1);
nPnts = size(EEG.data, 2);
nEp   = size(EEG.data, 3);

% --- Flatten data (channels x time) ---
EEG.data  = reshape(EEG.data, nChan, nPnts * nEp);

% --- Flatten icaact if present and compatible ---
if isfield(EEG,'icaact') && ~isempty(EEG.icaact) ...
        && ndims(EEG.icaact) == 3 && size(EEG.icaact,2) == nPnts && size(EEG.icaact,3) == nEp
    EEG.icaact = reshape(EEG.icaact, size(EEG.icaact,1), nPnts * nEp);
end

% --- Fix events: convert epoch-based latencies to continuous samples ---
if isfield(EEG,'event') && ~isempty(EEG.event)
    % In epoched data, event.latency is in samples from epoch start,
    % and event.epoch gives epoch index (1-based).
    if isfield(EEG.event, 'epoch')
        for k = 1:numel(EEG.event)
            if isfield(EEG.event(k),'epoch') && ~isempty(EEG.event(k).epoch)
                eIdx = EEG.event(k).epoch; % 1..nEp
                % latency within epoch is already in samples; shift by (epoch-1)*nPnts
                EEG.event(k).latency = EEG.event(k).latency + (eIdx - 1) * nPnts;
            end
        end
        % Remove epoch field after conversion
        EEG.event = rmfield(EEG.event, intersect(fieldnames(EEG.event), {'epoch'}));
    end

    % Rebuild urevent mapping if needed (optional—keep existing if present)
    if ~isfield(EEG,'urevent') || isempty(EEG.urevent)
        EEG.urevent = EEG.event;
        for k = 1:numel(EEG.event)
            EEG.event(k).urevent = k; %#ok<AGROW>
        end
    end
end

% --- Update header to continuous ---
EEG.trials = 1;
EEG.pnts   = size(EEG.data, 2);
EEG.epoch  = [];              % remove epoch info

% Continuous time vector in ms from 0
if isfield(EEG,'srate') && ~isempty(EEG.srate) && EEG.srate > 0
    EEG.times = (0:EEG.pnts-1) / EEG.srate * 1000;  % ms
    EEG.xmin  = 0;
    EEG.xmax  = (EEG.pnts-1) / EEG.srate;           % seconds
else
    % Fallback: maintain simple 1..N (legacy behavior)
    EEG.times = 1:EEG.pnts;
    EEG.xmin  = 0;
    EEG.xmax  = EEG.pnts;
end

% Optional consistency check (safe here; users can strip in AutoBatch if desired)
% EEG = eeg_checkset(EEG, 'eventconsistency');

% Return proper history line
com = 'EEG = convert2continuous(EEG);';
end
