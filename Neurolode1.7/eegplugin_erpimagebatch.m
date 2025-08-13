function vers = eegplugin_erpimagebatch(fig, ~, ~)
    vers = '1.0';
    menu = findobj(fig, 'tag', 'plot');
    uimenu(menu, 'label', 'ERP Image Batch Tool', ...
           'callback', 'pop_erpimage_batch(EEG);');
end
