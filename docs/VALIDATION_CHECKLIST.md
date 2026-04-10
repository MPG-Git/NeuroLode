# Validation Checklist

## 1) Static test harness (MATLAB, no EEGLAB launch required)
From repo root in MATLAB:

```matlab
addpath(fullfile(pwd, 'tests'));
run_neurolode_smoke_tests;
```

This runs:
- `test_public_api_inventory`
- `test_plugin_entry_static`

## 2) What static tests cover
- Public file inventory exists (core plugin/public wrappers).
- Full spectral wrapper family exists.
- Plugin entrypoint file contains expected callback references.
- Bootstrap call presence (`neurolode_addpath`).
- Spectral wrapper-to-helper wiring sanity (`nl_spectral_common(...)`).

## 3) Manual EEGLAB smoke tests (required before release)
1. Launch EEGLAB:
   ```matlab
   eeglab
   ```
2. Confirm **Neurolode** menu appears.
3. Run one spectral path:
   ```matlab
   EEG = pop_EEG_Spectral_Centroid_Time(EEG);
   ```
4. Run one export path:
   ```matlab
   EEG = pop_export2format(EEG);
   ```
5. Run one preprocessing utility:
   ```matlab
   [EEG, com] = convert2continuous(EEG);
   ```
6. Run one AutoBatch path:
   ```matlab
   [EEG, com] = pop_AutoBatch(EEG);
   ```

## 4) Optional quick static checks from shell
```bash
rg -n "^function" Neurolode1.7/*.m
rg -n "uimenu|callback|pop_" Neurolode1.7/eegplugin_Neurolode.m
```

## 5) Execution policy reminder
If MATLAB/EEGLAB is unavailable in CI/agent environments, do **not** fabricate results. Run static checks only and report manual steps explicitly.
