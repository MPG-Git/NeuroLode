function run_neurolode_demo(out)
if nargin<1, out=''; end
[here,out,cleanup]=demo_prepare(mfilename('fullpath'),out); %#ok<ASGLU>
addpath(fileparts(fileparts(here)));
assert(~isempty(which('pop_loadset')),'Start EEGLAB first');
assert(~isempty(which('spectralCentroid')),'MATLAB Audio Toolbox is required');
E=pop_loadset('filename','synthetic.set','filepath',fullfile(here,'data'));
cd(out); [~,exported]=export2format(E,'1:3',1,0,0,'.csv',out);
cells=readcell(exported); actual=cell2mat(cells(2:end,2:end));
t=(0:E.pnts-1)/E.srate;
oracle=1.5*[sin(2*pi*10*t);sin(2*pi*15*t);sin(2*pi*20*t)];
exportError=max(abs(actual-oracle),[],'all'); assert(exportError<1e-6);
[continuous,~]=convert2continuous(E);
assert(isequal(continuous.data,reshape(E.data,3,[])));
[~,com]=pop_EEG_Spectral_Centroid_Time(E,1:3,0,1,1);
f=dir('*SpectralCentroid_Time*.xlsx');
if isempty(f), f=dir('*SpectralCentroid_Time*.csv'); end
assert(numel(f)==1,'Expected one centroid export');
c=readcell(fullfile(out,f(1).name)); centroid=cell2mat(c(2:end,2:end));
assert(all(isfinite(centroid),'all')); writecell(c,fullfile(out,'centroid.csv'));
fid=fopen(fullfile(out,'history.txt'),'w'); fprintf(fid,'%s\n',com); fclose(fid);
fig=figure; fc=onCleanup(@()close(fig)); %#ok<NASGU>
plot(t,actual'); xlim([0 .5]); xlabel('Time (seconds)'); ylabel('Epoch mean (microvolts)');
legend('Cz: 10 Hz','Pz: 15 Hz','Fz: 20 Hz'); grid on;
print(fig,fullfile(out,'epoch_average.png'),'-dpng','-r120');
demo_verify(here,out,{'Channels','Epochs','ContinuousSamples','ExportMaxError', ...
 'CzMeanCentroidHz','PzMeanCentroidHz','FzMeanCentroidHz'}, ...
 [E.nbchan,E.trials,continuous.pnts,exportError,mean(centroid,2)']);
end
