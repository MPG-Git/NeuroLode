function run_neurolode_smoke_tests()
% run_neurolode_smoke_tests
% Lightweight static smoke harness for Neurolode.
%
% This script intentionally avoids launching EEGLAB automatically.
% It runs static checks and then prints manual smoke commands.

fprintf('Running Neurolode static smoke tests...\n');

test_public_api_inventory();
test_plugin_entry_static();

fprintf('\nStatic checks complete.\n');
fprintf('Manual EEGLAB smoke tests to run locally:\n');
fprintf('  1) eeglab\n');
fprintf('  2) Verify Neurolode menu appears in EEGLAB main window\n');
fprintf('  3) Spectral: EEG = pop_EEG_Spectral_Centroid_Time(EEG);\n');
fprintf('  4) Export:   EEG = pop_export2format(EEG);\n');
fprintf('  5) Preproc:  [EEG, com] = convert2continuous(EEG);\n');
fprintf('  6) AutoBatch: [EEG, com] = pop_AutoBatch(EEG);\n');

fprintf('\nDONE: run_neurolode_smoke_tests\n');
end
