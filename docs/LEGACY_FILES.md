# Legacy / ERP-Image Triage

## Supported ERP-image path (official)
- **Primary supported entrypoint:** `pop_erpimage_mg.m`
  - Invoked from Neurolode main plugin menu (`eegplugin_Neurolode.m`).

## File classification
| File | Classification | Rationale | Action |
|---|---|---|---|
| `eegplugin_erpimagebatch.m` | Compatibility wrapper | Secondary plugin hook used by older setups; still launches batch tool. | Kept in place with compatibility note. |
| `pop_erpimage_batch.m` | Shipping (secondary) | Current batch ERP-image implementation reachable via compatibility plugin. | Kept in place; marked supported secondary entrypoint. |
| `pop_erpimage_batch_old.m` | Legacy duplicate | Older duplicate implementation of `pop_erpimage_batch`. | Kept in place with deprecation note for safe recovery. |
| `pop_erpimage_mg.m` | Shipping (primary) | Main Neurolode ERP-image menu target. | Kept in place; designated official path. |
| `pop_erpimage_mg2.m` | Legacy/prototype | Alternate/legacy variant not used by main Neurolode menu flow. | Kept in place with deprecation note to avoid ambiguity. |

## Why legacy files were not moved in this pass
To preserve unknown user scripts and MATLAB path assumptions, legacy ERP-image files were **not moved** in this milestone. This avoids accidental breakage while still clarifying supported vs legacy status in-code and in docs.

## Safe recovery path
If a legacy behavior is needed, users can still call the legacy file directly from the current location. Future quarantining to `legacy/` should be done only after explicit confirmation and wrapper compatibility shims where needed.
