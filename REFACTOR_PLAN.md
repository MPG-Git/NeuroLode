# REFACTOR_PLAN.md

## Objective
Create a safe, milestone-based preservation refactor of the Neurolode EEGLAB plugin while keeping public entrypoints and behavior stable.

## Scope assumptions
- This plan does **not** alter algorithmic behavior.
- Public names and EEGLAB callback/history compatibility are preserved.
- Work is organized for incremental review with rollback points.

---

## Repository map (current)

### Root
- `README.md`, `LICENSE`
- `Neurolode1.7/` (primary source directory)

### Major code groups in `Neurolode1.7/`
1. **Plugin/menu entrypoints**
   - `eegplugin_Neurolode.m`
   - `eegplugin_erpimagebatch.m`
2. **Batch + GUI orchestration**
   - `pop_AutoBatch.m`, `pop_functionsettings.m`
   - `pop_MoveButton.m`, `pop_RemoveButton.m`, `pop_SaveNopen.m`, `pop_PrintFigure.m`
3. **Export pipeline**
   - `pop_export2format.m`, `export2format.m`
   - `pop_eeglab2sloreta.m`, `eeglab2sloreta.m`
4. **Data transform utilities**
   - `convert2continuous.m`, `pop_epochfile.m`, `pop_reduce_pca_by_one.m`
5. **Spectral analysis suite**
   - `pop_EEG_PowerSpectrumOss.m`
   - `pop_EEG_Spectral_{Centroid,Spread,Skewness,Kurtosis}_{Time,Freq,Custom}.m`
   - shared helper currently present: `nl_spectral_common.m`
6. **ERP image + plotting forks/wrappers**
   - `pop_erpimage_batch.m`, `pop_erpimage_batch_old.m`
   - `pop_erpimage_mg.m`, `pop_erpimage_mg2.m`, `pop_erpimage_mg.asv`
   - `eegplot_SpectrumOss.m`, `pop_eegplot_SpectrumOss.m`, `spectopoOss.m`
7. **Comparison utility**
   - `pop_CompareFFT.m`

---

## Identified preservation risks
1. **Name/file coupling and intentional overrides**
   - Several files intentionally mirror EEGLAB core names (`eegplot`, `spectopo`, `pop_eegplot`) via custom file names.
   - Risk: path order and callback resolution can change behavior unexpectedly.
2. **Legacy duplicates retained in tree**
   - `pop_erpimage_batch_old.m` duplicates public function naming intent.
   - `pop_erpimage_mg.asv` indicates editor backup artifact.
   - Risk: accidental path precedence or maintenance divergence.
3. **History/callback string dependence**
   - Many pop wrappers construct `com` strings manually.
   - Risk: tiny quoting/order changes can break reproducibility.
4. **GUI-driven workflows**
   - Input dialogs and appdata/userdata assumptions are heavily used.
   - Risk: refactors that reorder GUI state handling may break callbacks.
5. **Export side effects**
   - Filename conventions are user-visible and used in batch pipelines.
   - Risk: changing naming/timestamp behavior can break downstream scripts.

---

## Proposed final folder layout (target, compatibility-safe)

> Keep public entrypoint filenames in place (or thin wrappers) to preserve EEGLAB callback compatibility.

```text
Neurolode1.7/
  eegplugin_Neurolode.m
  eegplugin_erpimagebatch.m
  pop_*.m (public wrappers remain stable)

  core/
    batch/
    export/
    spectral/
    erpimage/
    plotting/
    utils/

  legacy/
    pop_erpimage_batch_old.m
    pop_erpimage_mg.asv
```

Migration rule:
- Public `pop_*` and plugin files remain as stable wrappers.
- Shared logic moves to `core/**` helpers gradually.
- Legacy artifacts stay available until explicit deprecation policy is approved.

---

## Milestones

## Milestone 0 — Baseline inventory and guardrails
**Goal:** Freeze public API map and behavior invariants before refactors.

**File list:**
- Add/update docs only (`AGENTS.md`, `REFACTOR_PLAN.md`, optional API inventory markdown).

**Acceptance criteria:**
- Canonical list of public entrypoints captured.
- Invariants documented (menu/callback/history stability).
- Validation checklist prepared.

---

## Milestone 1 — Spectral helper consolidation (non-algorithmic)
**Goal:** Remove duplicated helper utilities across spectral files without changing computations.

**Candidate files:**
- `pop_EEG_Spectral_*` family
- `nl_spectral_common.m` (or split by domain if needed)

**Acceptance criteria:**
- Public spectral function signatures unchanged.
- GUI text/options unchanged.
- `com` history string formats unchanged.
- Existing centroid helper extraction pattern extended safely to spread/skewness/kurtosis where duplicates exist.

**Validation focus:**
- Call each spectral variant via GUI + direct call.
- Compare output sizes/time vectors on a fixed dataset before/after.

---

## Milestone 2 — Export pipeline hardening (wrapper/core boundaries)
**Goal:** Clearly separate GUI wrapper (`pop_export2format`) and worker logic (`export2format`) while preserving output formats/names.

**Candidate files:**
- `pop_export2format.m`, `export2format.m`
- `pop_eeglab2sloreta.m`, `eeglab2sloreta.m`

**Acceptance criteria:**
- No changes to default file naming scheme unless explicitly approved.
- DAT/TXT/XLSX and sLORETA export paths continue to work.
- `pop_*` wrappers continue returning `[EEG, com]` contracts.

**Validation focus:**
- Golden-output sample export comparison (row/column counts and header conventions).

---

## Milestone 3 — Batch GUI stabilization
**Goal:** Improve maintainability in AutoBatch/UI code without changing user interactions.

**Candidate files:**
- `pop_AutoBatch.m`, `pop_functionsettings.m`
- `pop_MoveButton.m`, `pop_RemoveButton.m`, `pop_SaveNopen.m`

**Acceptance criteria:**
- Start/Stop recording semantics unchanged.
- Reordering/removal/editing operations preserved.
- Script generation remains compatible with existing saved workflows.

**Validation focus:**
- Record -> edit -> save/open -> replay sequence on 2+ datasets.

---

## Milestone 4 — ERP image and plotting compatibility pass
**Goal:** Reduce confusion around legacy/duplicate plotting files while preserving runtime behavior.

**Candidate files:**
- `pop_erpimage_batch.m`, `pop_erpimage_batch_old.m`
- `pop_erpimage_mg.m`, `pop_erpimage_mg2.m`
- `eegplot_SpectrumOss.m`, `pop_eegplot_SpectrumOss.m`, `spectopoOss.m`

**Acceptance criteria:**
- No public file renames.
- Path precedence and callback targets documented and tested.
- Legacy files explicitly marked as active/legacy in headers.

**Validation focus:**
- Open each plotting entrypoint from EEGLAB menus and command line.

---

## Milestone 5 — Optional layout migration with wrappers
**Goal:** Move internal logic to `core/**` while leaving stable public wrappers in `Neurolode1.7/`.

**Candidate files:**
- New `core/**` helper files
- Existing public wrappers adjusted to delegate only

**Acceptance criteria:**
- `which <public_function> -all` still resolves expected public entrypoint files.
- No callback/menu changes required by end users.
- Manual smoke tests pass unchanged.

---

## Validation commands (proposed)

### Static / repository checks
- `git status --short`
- `rg -n "^function" Neurolode1.7/*.m`
- `rg -n "uimenu|callback|pop_" Neurolode1.7/eegplugin_Neurolode.m Neurolode1.7/eegplugin_erpimagebatch.m`
- `rg -n "\bcom\b|eegh|vararg2str|history" Neurolode1.7/*.m`

### MATLAB / EEGLAB smoke tests (manual)
- `eeglab`
- `which eegplugin_Neurolode -all`
- `which pop_AutoBatch -all`
- `which pop_export2format -all`
- `which pop_eeglab2sloreta -all`
- `which pop_EEG_Spectral_Centroid_Time -all`
- `which pop_EEG_Spectral_Spread_Freq -all`
- `which pop_EEG_Spectral_Skewness_Custom -all`
- `which pop_EEG_Spectral_Kurtosis_Time -all`
- `which pop_erpimage_batch -all`
- `which pop_erpimage_mg -all`
- `which pop_eegplot -all`

Representative runtime calls:
- `EEG = pop_export2format(EEG);`
- `EEG = pop_eeglab2sloreta(EEG);`
- `EEG = pop_EEG_Spectral_Centroid_Time(EEG);`
- `EEG = pop_EEG_Spectral_Spread_Freq(EEG);`
- `EEG = pop_EEG_Spectral_Skewness_Custom(EEG);`
- `EEG = pop_EEG_Spectral_Kurtosis_Time(EEG);`
- `EEG = pop_AutoBatch(EEG);`

---

## Definition of done for planning step
- `AGENTS.md` documents purpose, API surface, invariants, and validation guidance.
- `REFACTOR_PLAN.md` defines phased milestones with acceptance criteria + candidate file lists.
- No algorithmic/functional code changes in this step.
