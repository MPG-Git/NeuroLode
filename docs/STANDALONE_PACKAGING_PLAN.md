# Standalone Packaging Plan

## Objective
Prepare Neurolode for two distribution modes while preserving current behavior:
1. **Neurolode Complete** (full plugin, current primary shipping target)
2. **Standalone workflow plugins** (Batch, Spectral, Export, sLORETA)

This plan is scaffolding-only and avoids immediate file moves.

---

## Core design principle
Use a **shared-core + thin-wrapper** model:
- **Shared core**: all algorithmic and reusable implementation code (single source of truth).
- **Thin wrappers/plugins**: package-specific `eegplugin_*` menus and `pop_*` entrypoints that call shared core.

### Why
- Avoid algorithm duplication across package variants.
- Prevent version drift between complete and standalone distributions.
- Keep EEGLAB callback/history behavior stable via wrapper continuity.

---

## Proposed package model

## 1) Neurolode Complete (primary)
**Purpose:** full current feature set.

**Plugin entrypoint**
- `eegplugin_Neurolode.m`

**Includes**
- All current public `pop_*` workflows and supporting files.
- Existing compatibility plugin(s) retained as needed.

**Status:** current shipping baseline.

---

## 2) Neurolode Batch (standalone)
**Purpose:** batch recording/editing/script generation workflow.

**Proposed plugin entrypoint**
- `eegplugin_Neurolode_Batch.m` (future wrapper plugin)

**Wrapper/API surface**
- `pop_AutoBatch.m`
- `pop_functionsettings.m`
- `pop_MoveButton.m`
- `pop_RemoveButton.m`
- `pop_SaveNopen.m`
- `pop_PrintFigure.m` (legacy helper, optional in first pass)

**Shared dependencies (must be shared, not duplicated)**
- Any common GUI/state utilities extracted later.

---

## 3) Neurolode Spectral (standalone)
**Purpose:** spectral metrics and related analysis wrappers.

**Proposed plugin entrypoint**
- `eegplugin_Neurolode_Spectral.m` (future wrapper plugin)

**Wrapper/API surface**
- `pop_EEG_Spectral_{Centroid,Spread,Skewness,Kurtosis}_{Time,Freq,Custom}.m`
- `pop_EEG_PowerSpectrumOss.m`

**Shared dependencies (must be shared, not duplicated)**
- `nl_spectral_common.m`
- plotting/utilities used by spectral wrappers where applicable.

---

## 4) Neurolode Export (standalone)
**Purpose:** table/file export workflows.

**Proposed plugin entrypoint**
- `eegplugin_Neurolode_Export.m` (future wrapper plugin)

**Wrapper/API surface**
- `pop_export2format.m`
- `export2format.m`

**Shared dependencies (must be shared, not duplicated)**
- shared filename/history formatting helpers (as extracted in future).

---

## 5) Neurolode sLORETA (standalone)
**Purpose:** sLORETA export workflow.

**Proposed plugin entrypoint**
- `eegplugin_Neurolode_sLORETA.m` (future wrapper plugin)

**Wrapper/API surface**
- `pop_eeglab2sloreta.m`
- `eeglab2sloreta.m`

**Shared dependencies (must be shared, not duplicated)**
- shared validation/path helpers as needed.

---

## Shared vs wrapper-only classification

### Must remain shared (single-source)
- Algorithmic workers:
  - `export2format.m`
  - `eeglab2sloreta.m`
  - spectral computations within each `pop_EEG_Spectral_*` wrapper (until deeper extraction is safe)
- Shared helpers:
  - `nl_spectral_common.m`
  - `neurolode_preproc_common.m`
  - `neurolode_addpath.m`

### Wrapper-only/package-local candidates
- Package-specific `eegplugin_*` menu files (thin routing only).
- Package-specific README/metadata/manifests.
- Optional compatibility wrappers that only delegate to shared core.

---

## Candidate file mapping (current -> package responsibility)

| File(s) | Complete | Batch | Spectral | Export | sLORETA | Notes |
|---|---:|---:|---:|---:|---:|---|
| `eegplugin_Neurolode.m` | ✅ |  |  |  |  | Primary plugin entrypoint |
| `pop_AutoBatch.m`, `pop_functionsettings.m`, `pop_MoveButton.m`, `pop_RemoveButton.m`, `pop_SaveNopen.m`, `pop_PrintFigure.m` | ✅ | ✅ |  |  |  | Batch module |
| `pop_EEG_Spectral_*`, `pop_EEG_PowerSpectrumOss.m` | ✅ |  | ✅ |  |  | Spectral module |
| `nl_spectral_common.m` | ✅ |  | ✅ |  |  | Shared helper (no duplication) |
| `pop_export2format.m`, `export2format.m` | ✅ |  |  | ✅ |  | Export module |
| `pop_eeglab2sloreta.m`, `eeglab2sloreta.m` | ✅ |  |  |  | ✅ | sLORETA module |
| `convert2continuous.m`, `pop_epochfile.m`, `pop_reduce_pca_by_one.m`, `neurolode_preproc_common.m` | ✅ | (optional) | (optional) | (optional) | (optional) | Shared preproc utilities; keep centralized |
| ERP-image compatibility files | ✅ |  |  |  |  | Keep with Complete for now |

---

## Implementation guardrails (future work)
1. Do not fork algorithms into per-package copies.
2. Introduce new standalone plugin entrypoints as wrappers only.
3. Keep current complete plugin as the reference implementation.
4. If package extraction requires path changes, route through `neurolode_addpath` and preserve wrapper signatures.
5. Add package-level smoke tests that call shared core from each wrapper package.

---

## Suggested rollout sequence
1. Add package manifests/docs only (no moves).
2. Add standalone `eegplugin_*` wrappers that call existing public `pop_*` files.
3. Add package-specific smoke checks in `tests/`.
4. Only then consider folder moves with compatibility wrappers.

This sequencing minimizes risk and keeps the complete plugin stable throughout.
