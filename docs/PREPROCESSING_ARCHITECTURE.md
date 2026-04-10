# Preprocessing Utilities Architecture (Preservation Refactor)

## Public entrypoints (stable)
- `convert2continuous.m`
- `pop_epochfile.m`
- `pop_reduce_pca_by_one.m`

These remain public and unchanged by name.

## Shared internal helper
- `Neurolode1.7/neurolode_preproc_common.m`

Current shared actions:
- `validate_eeg_input` — common EEG struct/data validation.
- `require_finite_scalar` — consistent scalar numeric validation for GUI/programmatic inputs.

## Intent
- Keep behavior and EEGLAB calling patterns stable.
- Reduce repeated input-validation snippets.
- Keep algorithmic logic in each public utility wrapper.
