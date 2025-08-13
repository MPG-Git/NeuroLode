The Neurolode EEGLAB Plugin is a modular extension for EEGLAB that streamlines batch EEG analysis, spectral metrics computation, and data export. It integrates interactive GUI workflows with fully scriptable pop_* functions, enabling reproducible, large-scale processing without sacrificing usability.
Exports EEG metrics as Excel, DAT, TXT, and ASC for sLORETA. Includes PCA reduction by 1, conversion between continuous and epoched data, and spectral analysis (Centroid, Kurtosis, Skewness, Spread). Features a modified BSS UI for enhanced batch and preprocessing workflows.

Key features include:
1.	Batch-Automation Framework
  o	An AutoBatch system that records, edits, and re-runs EEGLAB command sequences on multiple datasets.
  o	Integrated GUI for reviewing and modifying stored processing steps (pop_functionsettings), making pipelines editable and reusable.
2.	Custom Spectral Analysis Suite
  o	Built-in functions to compute Spectral Centroid, Spectral Spread, Spectral Skewness, and Spectral Kurtosis, each in time-resolved, frequency-resolved, or user-defined custom modes.
  o	Channel- and epoch-level averaging options.
  o	Automatic time-axis computation for accurate temporal alignment.
  o	Export in .xlsx with fallback to .csv or .txt for compatibility.
3.	Flexible Data Export Tools
  o	pop_export2format for exporting channel, frequency, or epoch-based metrics with rich metadata.
  o	Deterministic, descriptive filenames for batch reproducibility.
  o	Supports grand averages, individual channels, and arbitrary channel groupings.
4.	Preprocessing Utilities
  o	convert2continuous for reverting epoched datasets to continuous format while preserving events.
  o	pop_reduce_pca_by_one for progressive dimensionality reduction in ICA pipelines.
  o	pop_epochfile for creating epochs from external event files or custom triggers.
5.	sLORETA Integration
  o	eeglab2sloreta and pop_eeglab2sloreta for direct export to sLORETA, with robust file/folder handling and bad-channel removal.
6.	GUI Enhancements & Safety Improvements
  o	Modernized parent menu (eegplugin_Neurolode.m) with single-point callback handling, error-resistant history integration, and STUDY-aware menu items.
  o	Hardened GUI utilities (pop_MoveButton, pop_RemoveButton, pop_PrintFigure) to ensure stability and compatibility across EEGLAB versions.

Intended Use:
•	Ideal for researchers running multi-subject, multi-condition EEG studies who need reproducible pipelines that bridge interactive exploration and fully automated batch execution.
•	Suitable for both single-trial exploratory analysis and large-scale statistical workflows.
