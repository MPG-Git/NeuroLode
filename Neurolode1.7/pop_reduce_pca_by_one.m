function [EEG, com] = pop_reduce_pca_by_one(EEG)
% [EEG, com] = pop_reduce_pca_by_one(EEG)
% Reduce ICA dimensionality by 1 and re-run ICA using BINICA (if available)
% or RUNICA, with PCA pre-reduction to N-1.
%
% - Detects current number of ICs from EEG.icaweights when available.
% - Falls back to data rank when no ICA has been run yet.
% - No-op (with warning) if current dimensionality <= 1.
%
% Author: Matthew Phillip Gunn (refreshed 2025-08-13)

com = '';

if nargin < 1 || isempty(EEG)
    error('pop_reduce_pca_by_one: EEG dataset is required.');
end

% --- Determine current dimensionality N ---
% Prefer the number of rows in icaweights (actual IC count).
if isfield(EEG,'icaweights') && ~isempty(EEG.icaweights)
    currN = size(EEG.icaweights, 1);
elseif isfield(EEG,'icaact') && ~isempty(EEG.icaact)
    currN = size(EEG.icaact, 1);
else
    % If ICA hasn’t been run, estimate from data rank; cap by nbchan
    try
        currN = min(EEG.nbchan, eeg_rank(EEG));
    catch
        % Fallback (very conservative)
        currN = min(EEG.nbchan, rank(double(EEG.data(:,:))));
    end
end

targetN = max(0, currN - 1); % how many components we’ll keep via PCA

if currN <= 1 || targetN < 1
    warndlg('Current IC dimensionality ≤ 1. Nothing to reduce.','Reduce PCA by 1');
    % Return no-op command for EEGLAB history consistency
    com = 'pop_reduce_pca_by_one(EEG); % no-op (N<=1)';
    return;
end

% --- Choose ICA engine: BINICA preferred if present ---
useBinica = (exist('binica','file') == 2);

if useBinica
    % BINICA route
    com = sprintf(['EEG = pop_runica(EEG, ''extended'', 1, ''icatype'', ''binica'', ' ...
                   '''pca'', %d, ''verbose'', ''off'');'], targetN);
    EEG = pop_runica(EEG, 'extended', 1, 'icatype', 'binica', 'pca', targetN, 'verbose', 'off');
else
    % RUNICA route
    com = sprintf(['EEG = pop_runica(EEG, ''extended'', 1, ''icatype'', ''runica'', ' ...
                   '''pca'', %d, ''verbose'', ''off'');'], targetN);
    EEG = pop_runica(EEG, 'extended', 1, 'icatype', 'runica', 'pca', targetN, 'verbose', 'off');
end

end
