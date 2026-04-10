# Spectral Architecture (Preservation Refactor)

## Public API (stable)
The following public wrappers remain unchanged and continue to be the supported entrypoints:
- `pop_EEG_Spectral_Centroid_{Time,Freq,Custom}.m`
- `pop_EEG_Spectral_Spread_{Time,Freq,Custom}.m`
- `pop_EEG_Spectral_Skewness_{Time,Freq,Custom}.m`
- `pop_EEG_Spectral_Kurtosis_{Time,Freq,Custom}.m`

These wrappers still own GUI prompts, metric-specific computation, output formatting, and `com` history emission.

## Internal shared helpers
Common non-algorithmic utility logic is centralized in:
- `Neurolode1.7/nl_spectral_common.m`

Shared actions used by wrappers:
- `resolve_coi` (COI parsing: ranges/indices/labels)
- `chan_label` (channel label fallback)
- `coi_for_history` (history-safe COI serialization)
- `strip_ext` (filename stem extraction)
- `iff` / `avg_label` (small formatting helpers)

## Design intent
- Reduce duplicated helper code across spectral wrappers.
- Preserve public file names, function signatures, callbacks, and history behavior.
- Keep wrapper files separate and explicit (no merged public super-wrapper).

## Notes
- `pop_EEG_Spectral_Spread_Time.m` retains a few local helper functions (`avg_or_first_label`, `export_tag`, `try_writecell`) because they encapsulate wrapper-specific behavior not shared across the full family.
