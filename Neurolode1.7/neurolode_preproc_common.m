function varargout = neurolode_preproc_common(action, varargin)
% neurolode_preproc_common
% Shared validation helpers for Neurolode preprocessing utilities.

switch lower(action)
    case 'validate_eeg_input'
        validate_eeg_input(varargin{1}, varargin{2});
    case 'require_finite_scalar'
        require_finite_scalar(varargin{1}, varargin{2}, varargin{3});
    otherwise
        error('neurolode_preproc_common:UnknownAction', 'Unknown action: %s', string(action));
end

if nargout > 0
    varargout = cell(1,nargout);
end
end

function validate_eeg_input(EEG, caller)
if nargin < 2 || isempty(caller), caller = 'Neurolode'; end
if nargin < 1 || isempty(EEG) || ~isstruct(EEG)
    error('%s: EEG dataset struct is required.', caller);
end
if ~isfield(EEG,'data') || isempty(EEG.data)
    error('%s: EEG.data is required.', caller);
end
end

function require_finite_scalar(x, name, caller)
if nargin < 3 || isempty(caller), caller = 'Neurolode'; end
if ~(isnumeric(x) && isscalar(x) && isfinite(x))
    error('%s: %s must be a finite scalar.', caller, name);
end
end
