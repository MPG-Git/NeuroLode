function test_plugin_entry_static()
% test_plugin_entry_static
% Static sanity checks for plugin entrypoint/menu wiring.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
pluginFile = fullfile(repoRoot, 'Neurolode1.7', 'eegplugin_Neurolode.m');
assert(exist(pluginFile, 'file') == 2, 'Missing eegplugin_Neurolode.m');

txt = fileread(pluginFile);

% Entry + bootstrap checks.
assert(contains(txt, 'function vers = eegplugin_Neurolode'), 'Entrypoint signature missing.');
assert(contains(txt, 'neurolode_addpath'), 'Bootstrap call missing in eegplugin_Neurolode.m.');

% Menu callback sanity (static substring checks).
requiredCallbacks = {
    'pop_AutoBatch(EEG)'
    'pop_export2format(EEG)'
    'pop_eeglab2sloreta(EEG)'
    'pop_EEG_Spectral_Centroid_Time(EEG, 1)'
    'pop_EEG_Spectral_Spread_Time(EEG, 1)'
    'pop_EEG_Spectral_Skewness_Time(EEG, 1)'
    'pop_EEG_Spectral_Kurtosis_Time(EEG, 1)'
    'pop_EEG_PowerSpectrumOss(EEG, 1)'
    'pop_CompareFFT(EEG, 1)'
};
for i = 1:numel(requiredCallbacks)
    assert(contains(txt, requiredCallbacks{i}), 'Missing menu callback reference: %s', requiredCallbacks{i});
end

% Wrapper-to-helper wiring sanity: spectral wrappers should reference shared helper.
srcRoot = fullfile(repoRoot, 'Neurolode1.7');
metrics = {'Centroid','Spread','Skewness','Kurtosis'};
modes   = {'Time','Freq','Custom'};
for m = 1:numel(metrics)
    for k = 1:numel(modes)
        fn = fullfile(srcRoot, sprintf('pop_EEG_Spectral_%s_%s.m', metrics{m}, modes{k}));
        ftxt = fileread(fn);
        assert(contains(ftxt, 'nl_spectral_common('), 'Expected shared helper wiring missing: %s', fn);
    end
end

fprintf('PASS: test_plugin_entry_static\n');
end
