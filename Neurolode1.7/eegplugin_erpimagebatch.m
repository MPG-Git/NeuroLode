function vers = eegplugin_erpimagebatch(fig, ~, ~)
    % Compatibility plugin wrapper (legacy):
    % - Kept for users who still load this plugin entrypoint directly.
    % - Supported ERP-image menu path is eegplugin_Neurolode -> pop_erpimage_mg.
    vers = '1.0';
    menu = findobj(fig, 'tag', 'plot');
    uimenu(menu, 'label', 'ERP Image Batch Tool', ...
           'callback', 'pop_erpimage_batch(EEG);');
end
