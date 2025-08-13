% pop_erpimage_batch.m - Batch ERP Image Plugin with Averaging, Contrast, and Permutation Test
function pop_erpimage_batch(EEG, compList, eventTypeList, varargin)

if nargin < 1 || isempty(EEG)
    error('EEG dataset must be provided.');
end

if nargin < 3 || isempty(compList) || isempty(eventTypeList)
    [userInputs, okPressed] = inputgui_advanced(EEG);
    if ~okPressed, return; end
    compList = userInputs.compList;
    eventTypeList = userInputs.eventTypeList;
    varargin = userInputs.varargin;
end

% -------------------------
% Parse parameters
% -------------------------
p = inputParser;
addParameter(p, 'TypePlot', 0);
addParameter(p, 'ProjChan', []);
addParameter(p, 'Smooth', 5);
addParameter(p, 'Decimate', 1);
addParameter(p, 'SortingWin', []);
addParameter(p, 'SortingField', 'latency');
addParameter(p, 'Mode', 'average');
addParameter(p, 'Condition2', []);
addParameter(p, 'NPermutations', 1000);
addParameter(p, 'SaveCSV', true);
addParameter(p, 'ERPLine', true);
addParameter(p, 'Colorbar', true);
addParameter(p, 'Topo', false);
parse(p, varargin{:});
prm = p.Results;

fprintf('Starting pop_erpimage_batch in %s mode...\n', prm.Mode);
times = linspace(EEG.xmin*1000, EEG.xmax*1000, EEG.pnts);

allImgs = [];
labels = {};

% -------------------------
% Process images
% -------------------------
for comp = compList
    for evtIdx = 1:length(eventTypeList)
        evtType = eventTypeList{evtIdx};

        sortLat = eeg_getepochevent(EEG, evtType, prm.SortingWin, prm.SortingField);

        if prm.TypePlot == 1
            dat = squeeze(mean(EEG.data(comp,:,:), 3));
        else
            dat = eeg_getdatact(EEG, 'component', comp, 'projchan', prm.ProjChan);
        end

        [ersp, ~] = erpimage(dat, sortLat, times, '', prm.Smooth, prm.Decimate, ...
            'erp', fastif(prm.ERPLine, 'on', 'off'), 'cbar', fastif(prm.Colorbar, 'on', 'off'), 'noplot', 'on');

        allImgs = cat(3, allImgs, ersp);
        labels{end+1} = sprintf('C%d-%s', comp, evtType);
    end
end

% -------------------------
% Handle modes
% -------------------------
switch prm.Mode
    case 'individual'
        for i = 1:size(allImgs, 3)
            fig = figure; imagesc(times, 1:size(allImgs,1), allImgs(:,:,i));
            title(sprintf('ERP Image: %s', labels{i})); if prm.Colorbar, colorbar; end
            saveas(fig, sprintf('ERPImage_%s.png', labels{i}));
        end

    case 'average'
        avgImg = mean(allImgs, 3);
        fig = figure; imagesc(times, 1:size(avgImg,1), avgImg);
        title('Averaged ERP Image'); if prm.Colorbar, colorbar; end
        if prm.SaveCSV
            csvwrite('avg_erpimage.csv', avgImg);
            fprintf('Saved averaged ERP image to avg_erpimage.csv\n');
        end
        saveas(fig, 'Averaged_ERP_Image.png');

    case 'contrast'
        nCond = size(allImgs, 3) / 2;
        img1 = mean(allImgs(:,:,1:nCond), 3);
        img2 = mean(allImgs(:,:,nCond+1:end), 3);
        contrastImg = img1 - img2;

        nPerm = prm.NPermutations;
        fprintf('Running permutation test (%d iterations)...\n', nPerm);
        allData = cat(3, allImgs(:,:,1:nCond), allImgs(:,:,nCond+1:end));
        labels_perm = [ones(1,nCond), 2*ones(1,nCond)];
        permDist = zeros(size(contrastImg,1), size(contrastImg,2), nPerm);

        for i = 1:nPerm
            idx = labels_perm(randperm(length(labels_perm)));
            grp1 = mean(allData(:,:,idx==1), 3);
            grp2 = mean(allData(:,:,idx==2), 3);
            permDist(:,:,i) = grp1 - grp2;
        end

        pVals = mean(abs(permDist) >= abs(contrastImg), 3);

        fig1 = figure; imagesc(times, 1:size(contrastImg,1), contrastImg);
        title('Contrast Image (Cond1 - Cond2)'); if prm.Colorbar, colorbar; end
        fig2 = figure; imagesc(times, 1:size(pVals,1), pVals); caxis([0 0.05]);
        title('Permutation p-values'); colorbar;

        if prm.SaveCSV
            csvwrite('contrast_img.csv', contrastImg);
            csvwrite('pvals_img.csv', pVals);
            fprintf('Saved contrast to contrast_img.csv and p-values to pvals_img.csv\n');
        end
        saveas(fig1, 'Contrast_Image.png');
        saveas(fig2, 'Permutation_PValues.png');

    otherwise
        error('Unknown mode: %s', prm.Mode);
end

fprintf('Done.\n');
end

function fast = fastif(cond, a, b)
if cond
    fast = a;
else
    fast = b;
end
end
