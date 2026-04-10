# Neurolode (EEGLAB Plugin)

Neurolode is an EEGLAB plugin for reproducible EEG processing workflows that combine interactive GUI use with scriptable `pop_*` entrypoints. The project focuses on:
- batch workflow capture/edit/replay,
- spectral metric analysis wrappers,
- export pipelines,
- preprocessing helpers,
- sLORETA export,
- ERP-image/plotting utilities.

> Primary plugin entrypoint: `Neurolode1.7/eegplugin_Neurolode.m`.

---

## Who this is for
Neurolode is intended for EEG researchers and labs who need to:
- run similar pipelines across many datasets,
- keep traceable EEGLAB history/callback workflows,
- switch between GUI-driven exploration and scripted execution.

---

## Core workflows
1. **AutoBatch workflow editing**
   - Record command history, reorder/remove operations, and save runnable batch scripts.
2. **Spectral analysis wrappers**
   - Spectral Centroid/Spread/Skewness/Kurtosis in Time/Freq/Custom variants.
3. **Export workflows**
   - Export EEG-derived outputs for downstream analysis (`.xlsx` / `.csv` / `.txt` / `.dat`) and sLORETA path.
4. **Preprocessing utilities**
   - Convert epoched→continuous, epoch wrappers, and PCA-by-one ICA convenience helper.
5. **ERP-image and plotting utilities**
   - ERP-image and related plotting integration paths retained for compatibility.

---

## Installation

## Prerequisites
- MATLAB
- EEGLAB installed and launchable (`eeglab`)

## Install from source
1. Clone or copy this repository.
2. Add `Neurolode1.7/` to your MATLAB path.
3. Launch EEGLAB:
   ```matlab
   eeglab
   ```
4. Confirm the **Neurolode** menu appears.

If needed, the plugin bootstrap helper can be used to add optional subfolders:
- `Neurolode1.7/neurolode_addpath.m`

---

## Quick start
From an EEGLAB session with a loaded dataset:

```matlab
% AutoBatch GUI
[EEG, com] = pop_AutoBatch(EEG);

% Spectral wrapper example
[EEG, com] = pop_EEG_Spectral_Centroid_Time(EEG);

% Export wrapper example
[EEG, com] = pop_export2format(EEG);

% Preprocessing helper example
[EEG, com] = convert2continuous(EEG);

% sLORETA wrapper example
[EEG, com] = pop_eeglab2sloreta(EEG);
```

---

## Major functions by workflow

## AutoBatch
- `pop_AutoBatch`
- `pop_functionsettings`
- `pop_MoveButton`
- `pop_RemoveButton`
- `pop_SaveNopen`
- `pop_PrintFigure` (legacy helper path)

## Spectral analysis
- `pop_EEG_Spectral_Centroid_{Time,Freq,Custom}`
- `pop_EEG_Spectral_Spread_{Time,Freq,Custom}`
- `pop_EEG_Spectral_Skewness_{Time,Freq,Custom}`
- `pop_EEG_Spectral_Kurtosis_{Time,Freq,Custom}`
- `pop_EEG_PowerSpectrumOss`

## Export
- `pop_export2format`
- `export2format`

## Preprocessing utilities
- `convert2continuous`
- `pop_epochfile`
- `pop_reduce_pca_by_one`

## sLORETA
- `pop_eeglab2sloreta`
- `eeglab2sloreta`

## ERP-image / plotting
- `pop_erpimage_mg` (supported primary ERP-image GUI entrypoint)
- `pop_erpimage_batch` (supported secondary/compatibility path)
- `eegplot_SpectrumOss`, `pop_eegplot_SpectrumOss`, `spectopoOss`

---

## Validation and known limitations

## Validation
Use the lightweight static harness in MATLAB:

```matlab
addpath(fullfile(pwd, 'tests'));
run_neurolode_smoke_tests;
```

Detailed local validation steps (including manual EEGLAB smoke tests):
- [`docs/VALIDATION_CHECKLIST.md`](docs/VALIDATION_CHECKLIST.md)

## Known limitations
- This repository does not include automated EEGLAB GUI integration tests.
- Manual EEGLAB confirmation remains required before release.
- Some ERP-image files are legacy/compatibility paths and are documented explicitly.

---

## Repository layout
- `Neurolode1.7/` — plugin source and public entrypoints.
- `docs/` — architecture, validation, and release-planning documents.
- `tests/` — lightweight static smoke-test scripts.
- `legacy/` — quarantined non-source artifacts and legacy references.

---

## Legacy note
Legacy/compatibility ERP-image files and support status are documented here:
- [`docs/LEGACY_FILES.md`](docs/LEGACY_FILES.md)

Neurolode keeps compatibility paths where possible, but the primary supported plugin route remains `eegplugin_Neurolode.m`.
