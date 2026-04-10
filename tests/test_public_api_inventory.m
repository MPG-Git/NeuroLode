function test_public_api_inventory()
% test_public_api_inventory
% Lightweight static inventory check for Neurolode public API files.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
srcRoot  = fullfile(repoRoot, 'Neurolode1.7');

requiredFiles = {
    'eegplugin_Neurolode.m'
    'eegplugin_erpimagebatch.m'
    'pop_AutoBatch.m'
    'pop_functionsettings.m'
    'pop_export2format.m'
    'export2format.m'
    'eeglab2sloreta.m'
    'pop_eeglab2sloreta.m'
    'convert2continuous.m'
    'pop_epochfile.m'
    'pop_reduce_pca_by_one.m'
    'pop_CompareFFT.m'
    'pop_EEG_PowerSpectrumOss.m'
    'pop_erpimage_batch.m'
    'pop_erpimage_mg.m'
    'eegplot_SpectrumOss.m'
    'pop_eegplot_SpectrumOss.m'
    'spectopoOss.m'
};

for i = 1:numel(requiredFiles)
    fp = fullfile(srcRoot, requiredFiles{i});
    assert(exist(fp, 'file') == 2, 'Missing required API file: %s', requiredFiles{i});
end

% Ensure full spectral family wrappers exist.
metrics = {'Centroid','Spread','Skewness','Kurtosis'};
modes   = {'Time','Freq','Custom'};
for m = 1:numel(metrics)
    for k = 1:numel(modes)
        fn = sprintf('pop_EEG_Spectral_%s_%s.m', metrics{m}, modes{k});
        assert(exist(fullfile(srcRoot, fn), 'file') == 2, 'Missing spectral wrapper: %s', fn);
    end
end

fprintf('PASS: test_public_api_inventory\n');
end
