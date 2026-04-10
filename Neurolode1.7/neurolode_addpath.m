function neurolode_addpath(rootDir)
% neurolode_addpath
% Ensure Neurolode plugin folders are on MATLAB path.
%
% Usage:
%   neurolode_addpath();
%   neurolode_addpath('/full/path/to/Neurolode1.7');
%
% Notes:
% - Safe to call multiple times.
% - Designed for preservation refactors where internals may move to
%   optional subfolders while keeping public entrypoints stable.

if nargin < 1 || isempty(rootDir)
    rootDir = fileparts(mfilename('fullpath'));
end

if ~isfolder(rootDir)
    return;
end

% Keep root first so legacy public entrypoints remain discoverable.
add_if_missing(rootDir);

% Optional internal folders for future organization.
subfolders = { ...
    'core', ...
    fullfile('core','batch'), ...
    fullfile('core','export'), ...
    fullfile('core','spectral'), ...
    fullfile('core','erpimage'), ...
    fullfile('core','plotting'), ...
    fullfile('core','utils'), ...
    'legacy', ...
    'docs', ...
    'tests' ...
};

for i = 1:numel(subfolders)
    d = fullfile(rootDir, subfolders{i});
    if isfolder(d)
        add_if_missing(d);
    end
end

end

function add_if_missing(d)
if exist(d, 'dir') ~= 7
    return;
end

p = path;
if isempty(strfind([pathsep p pathsep], [pathsep d pathsep])) %#ok<STREMP>
    addpath(d, '-end');
end
end
