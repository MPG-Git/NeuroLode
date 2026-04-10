# AGENTS.md

## Repository purpose
NeuroLode is an **EEGLAB MATLAB plugin** focused on:
- batch processing workflow capture/replay,
- spectral metric analysis (centroid/spread/skewness/kurtosis),
- ERP-image tooling,
- export bridges (Excel/TXT/DAT/sLORETA), and
- GUI/menu convenience utilities.

This repository should be treated as a **preservation refactor codebase**, not a rewrite.

---

## Public API surface (must remain stable)

### EEGLAB plugin entrypoints
- `Neurolode1.7/eegplugin_Neurolode.m`
- `Neurolode1.7/eegplugin_erpimagebatch.m` (legacy/secondary plugin hook)

### User-facing pop/utility entrypoints (stable names + call signatures)
- `pop_AutoBatch.m`
- `pop_functionsettings.m`
- `pop_export2format.m`
- `export2format.m`
- `eeglab2sloreta.m`
- `pop_eeglab2sloreta.m`
- `convert2continuous.m`
- `pop_epochfile.m`
- `pop_reduce_pca_by_one.m`
- `pop_CompareFFT.m`
- `pop_EEG_PowerSpectrumOss.m`
- `pop_EEG_Spectral_*` (all centroid/spread/skewness/kurtosis variants)
- `pop_erpimage_batch.m`
- `pop_erpimage_batch_old.m` (legacy duplicate kept for compatibility/archive)
- `pop_erpimage_mg.m`
- `pop_erpimage_mg2.m`
- `eegplot_SpectrumOss.m`
- `pop_eegplot_SpectrumOss.m`
- `spectopoOss.m`
- GUI helpers: `pop_MoveButton.m`, `pop_RemoveButton.m`, `pop_PrintFigure.m`, `pop_SaveNopen.m`

> Preservation invariant: do not rename/remove public files or break command-history replay compatibility.

---

## Non-negotiable invariants for all refactors
1. **Do not rename `eegplugin_Neurolode.m`.**
2. **Do not rename public `pop_*` functions.**
3. **Preserve EEGLAB menu labels/callback behavior** from plugin entrypoints.
4. **Preserve `com`/`eegh` history string compatibility** (including argument order and quoting style).
5. **No algorithmic behavior changes** unless explicitly requested and validated.
6. Prefer extracting shared helpers over changing user-visible behavior.
7. Keep legacy files (`*_old`, `.asv`, alternate wrappers) unless explicitly approved for removal.

---

## Current structure notes
- Source is mostly flat under `Neurolode1.7/`.
- The codebase mixes:
  - modernized wrappers with input validation,
  - legacy EEGLAB-derived files,
  - duplicated helper logic,
  - archived/legacy variants (`pop_erpimage_batch_old.m`, `pop_erpimage_mg.asv`).

Potentially sensitive compatibility details:
- `eegplot_SpectrumOss.m` defines `eegplot` and `spectopoOss.m` defines `spectopo` (intentional shadow/fork pattern).
- `pop_eegplot_SpectrumOss.m` defines `pop_eegplot` in a differently named file.
- `pop_erpimage_mg2.m` appears to carry legacy `pop_erpimage`-style content.

Do not “clean these up” by renaming in preservation passes.

---

## Validation workflow for any change

### Static checks (always runnable)
- Confirm modified file list is intentional:
  - `git status --short`
- Inspect API signatures for accidental renames:
  - `rg -n "^function" Neurolode1.7/*.m`
- Confirm plugin menu callbacks still reference valid entrypoints:
  - `rg -n "uimenu|callback|pop_" Neurolode1.7/eegplugin_Neurolode.m Neurolode1.7/eegplugin_erpimagebatch.m`
- Check history-string code paths in touched `pop_*` files:
  - `rg -n "\bcom\b|eegh|vararg2str|history" Neurolode1.7/<touched>.m`

### Manual MATLAB/EEGLAB smoke tests (required before release)
1. Launch EEGLAB:
   - `eeglab`
2. Verify plugin menu loads once and items are clickable:
   - Neurolode menu + submenus (`Common Commands`, `Export Data`, `Analysis`, `Compare`).
3. Run representative commands from GUI and command line:
   - `EEG = pop_export2format(EEG);`
   - `EEG = pop_eeglab2sloreta(EEG);`
   - `EEG = pop_EEG_Spectral_Centroid_Time(EEG);`
   - `EEG = pop_EEG_Spectral_Spread_Freq(EEG);`
   - `EEG = pop_EEG_Spectral_Skewness_Custom(EEG);`
   - `EEG = pop_EEG_Spectral_Kurtosis_Time(EEG);`
4. Confirm history replay:
   - inspect `EEG.history` and re-run captured calls on a fresh dataset.
5. Validate export side effects:
   - expected files are produced (.xlsx fallback behavior, DAT/TXT/ASC paths).

If MATLAB/EEGLAB is unavailable in CI/agent environment, do not fabricate results; provide commands above and report limitation.

---

## Refactor style guidance
- Target **small milestones** with explicit acceptance criteria.
- For duplicate code, introduce private/shared helpers while preserving APIs.
- Prefer additive migration (new helper + existing wrappers) over structural churn.
- Keep user-facing defaults, GUI text, and callback call forms stable.
- Document risks before touching legacy compatibility files.

## Path/bootstrap strategy
- `eegplugin_Neurolode.m` remains the canonical public EEGLAB entrypoint.
- On load, the plugin should call `neurolode_addpath(...)` to add optional internal subfolders if they exist.
- Keep plugin root discoverable and preserve callback resolution for existing public `pop_*` files.
- Bootstrap must be idempotent and safe if future subfolders are absent.

