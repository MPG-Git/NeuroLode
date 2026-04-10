# AutoBatch / UI Notes (Preservation Refactor)

## Main flow
1. `pop_AutoBatch.m` opens the AutoBatch GUI and captures `ALLCOM` snapshots.
2. Button callbacks manipulate per-figure `userdata`:
   - `pop_functionsettings` edits a selected operation string.
   - `pop_MoveButton` reorders grouped controls for one operation.
   - `pop_RemoveButton` removes one operation block.
   - `pop_SaveNopen` writes a runnable batch script and opens it in the MATLAB editor.
3. `pop_PrintFigure` is a GUI helper used from this workflow context.

## Key state assumptions
- GUI state is carried in figure `userdata` fields:
  - `OrderName`, `OrderNum`, `Operation`, `UpDownButtonRun`, optional `POS`.
- Movement/removal assumes operation controls are grouped by shared order index.
- `pop_AutoBatch` may be called from callbacks (`gcbf`) and must recover the right figure.

## Fragile areas (still risky)
- String-based callbacks mean errors can be silent if required variables are missing from callback scope.
- Parsing/rewriting operation strings in `pop_functionsettings` is best-effort and not a full parser.
- `pop_SaveNopen` script template still assumes a specific folder convention (`0_Pre`, `0_Post`).
- `pop_PrintFigure` remains legacy and lightly hardened; behavior depends on expected AutoBatch userdata shape.

## Preservation constraints kept
- Public function names unchanged.
- No workflow redesign or UI rewrite.
- EEGLAB integration path remains callback-compatible.
