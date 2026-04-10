# Repo Layout (Current + Intended)

## Current source-of-truth layout
- `Neurolode1.7/` — plugin MATLAB source (`eegplugin_*`, public `pop_*`, analysis/export helpers).
- `docs/` — repository documentation and planning notes.
- `tests/` — placeholder for future validation scripts/checks.
- `legacy/` — quarantined non-source or legacy artifacts kept for reference.

## Current quarantined artifacts
- `legacy/pop_erpimage_mg.asv` — MATLAB autosave backup moved out of source tree.

## Intended layout direction (preservation refactor)
- Keep all public entrypoint `.m` files discoverable and stable for EEGLAB compatibility.
- Gradually move non-runtime artifacts and legacy clutter to `legacy/`.
- Add reproducible manual/automated checks under `tests/` without changing runtime behavior.

## Bootstrap/path policy
- `eegplugin_Neurolode.m` is the canonical plugin entrypoint.
- `neurolode_addpath.m` can safely add optional subfolders (for future organization) without changing public callback names.
- Public `pop_*` entrypoints remain stable and path-discoverable from the plugin root.

