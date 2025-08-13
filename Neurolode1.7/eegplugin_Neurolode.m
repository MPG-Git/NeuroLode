function vers = eegplugin_Neurolode(fig, try_strings, catch_strings)
% eegplugin_Neurolode()
% Parent menu for Neurolode utilities (EEGLAB)
% Adds analysis, export, and convenience commands developed at INL.
% Author: Matthew Phillip Gunn (Carbondale, IL), updated 2025-08-13

vers = '1.7.0';
if nargin < 1 || isempty(fig), return; end

% Reuse existing menu if already present (avoid duplicates on rehash)
ParentMenu = findobj(fig, 'tag', 'neurolode_menu');
if isempty(ParentMenu)
    ParentMenu = uimenu(fig, 'label', 'Neurolode', 'tag', 'neurolode_menu');
else
    delete(allchild(ParentMenu));
end

% ---- try/catch helpers from EEGLAB (if available) ----
ts = '';
cs = '';
if nargin >= 2 && isstruct(try_strings) && isfield(try_strings,'no_check')
    ts = try_strings.no_check;
end
if nargin >= 3 && isstruct(catch_strings) && isfield(catch_strings,'new_and_hist')
    cs = catch_strings.new_and_hist;
end

% Build a standardized callback that:
% 1) runs a pop_* command returning [EEG, com]
% 2) logs it with eegh
% 3) stores EEG back into ALLEEG/CURRENTSET
% 4) redraws EEGLAB
    function cb = mkcb(popcall)
        % popcall example: 'pop_erpimage_mg(EEG)'
        body = [ ...
            '[EEG, com] = ' popcall ';' ...
            'if ~isempty(com),' ...
                'EEG = eegh(com, EEG);' ...
                '[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);' ...
                'eeglab(''redraw'');' ...
            'end;' ...
        ];
        cb = [ts body cs];
    end

% Add a menu item if the underlying function exists; otherwise add disabled
    function add_item(parent, label, popcall, varargin)
        % Extract function name before '(' to test existence
        fn = regexp(popcall, '^\s*([a-zA-Z0-9_]+)\s*\(', 'tokens','once');
        fn = iff(~isempty(fn), fn{1}, '');
        enabledFlag = 'on';
        if isempty(fn) || exist(fn,'file')~=2 && exist(fn,'builtin')~=5
            enabledFlag = 'off'; % keep visible but disabled so users see the feature list
        end
        uimenu(parent, 'label', label, 'callback', mkcb(popcall), 'enable', enabledFlag, varargin{:});
    end

% Tiny inline ternary helper
    function out = iff(cond, a, b), if cond, out = a; else, out = b; end, end

% -------------------------
% Top-level items
% -------------------------
add_item(ParentMenu, 'ERP Image Batch Tool',        'pop_erpimage_mg(EEG)');

add_item(ParentMenu, 'AutoBatch', ...
    '[EEG, com] = pop_AutoBatch(EEG);');

% -------------------------
% Common Commands
% -------------------------
CC = uimenu(ParentMenu, 'label', 'Common Commands');

add_item(CC, 'Reduce PCA by 1', ...
    'pop_reduce_pca_by_one(EEG)');

add_item(CC, 'Convert to Continuous', ...
    'convert2continuous(EEG)');

add_item(CC, 'Convert to Epoch', ...
    'pop_epochfile(EEG)');

% -------------------------
% Export Data
% -------------------------
Export0 = uimenu(ParentMenu, 'label', 'Export Data', 'separator', 'on');

add_item(Export0, 'As Excel', ...
    'pop_export2format(EEG)');

add_item(Export0, 'As DAT/Nscan', ...
    'pop_export2format(EEG, 1)');

add_item(Export0, 'As TXT', ...
    'pop_export2format(EEG, 1, 1)');

add_item(Export0, 'to sLORETA', ...
    'pop_eeglab2sloreta(EEG)');

% If you want a “fully custom” sLORETA call, keep a second (disabled by default) line like:
% add_item(Export0, 'to sLORETA (custom)', 'pop_eeglab2sloreta(EEG,1,1,1)');

% -------------------------
% Analysis
% -------------------------
Analysis0 = uimenu(ParentMenu, 'label', 'Analysis');

% Spectral Centroid
SC0 = uimenu(Analysis0, 'label', 'Spectral Centroid');
add_item(SC0, 'Time-Domain',       'pop_EEG_Spectral_Centroid_Time(EEG, 1)');
add_item(SC0, 'Frequency-Domain',  'pop_EEG_Spectral_Centroid_Freq(EEG, 1)');
add_item(SC0, 'Customize',         'pop_EEG_Spectral_Centroid_Custom(EEG, 1)');

% Spectral Spread
SS0 = uimenu(Analysis0, 'label', 'Spectral Spread');
add_item(SS0, 'Time-Domain',       'pop_EEG_Spectral_Spread_Time(EEG, 1)');
add_item(SS0, 'Frequency-Domain',  'pop_EEG_Spectral_Spread_Freq(EEG, 1)');
add_item(SS0, 'Customize',         'pop_EEG_Spectral_Spread_Custom(EEG, 1)');

% Spectral Skewness
SSk0 = uimenu(Analysis0, 'label', 'Spectral Skewness');
add_item(SSk0, 'Time-Domain',      'pop_EEG_Spectral_Skewness_Time(EEG, 1)');
add_item(SSk0, 'Frequency-Domain', 'pop_EEG_Spectral_Skewness_Freq(EEG, 1)');
add_item(SSk0, 'Customize',        'pop_EEG_Spectral_Skewness_Custom(EEG, 1)');

% Spectral Kurtosis
SK0 = uimenu(Analysis0, 'label', 'Spectral Kurtosis');
add_item(SK0, 'Time-Domain',       'pop_EEG_Spectral_Kurtosis_Time(EEG, 1)');
add_item(SK0, 'Frequency-Domain',  'pop_EEG_Spectral_Kurtosis_Freq(EEG, 1)');
add_item(SK0, 'Customize',         'pop_EEG_Spectral_Kurtosis_Custom(EEG, 1)');

% Power Spectrum Oscillation
add_item(Analysis0, 'Power Spectrum Oscillation', ...
    'pop_EEG_PowerSpectrumOss(EEG, 1)');

% -------------------------
% Compare
% -------------------------
Compare0 = uimenu(ParentMenu, 'label', 'Compare');
add_item(Compare0, 'FFT', 'pop_CompareFFT(EEG, 1)');

end
