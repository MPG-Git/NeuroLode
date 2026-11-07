function tests = test_runtime
% Runtime regression tests. Add EEGLAB core and Audio Toolbox to the path.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'Neurolode1.7'));
testCase.TestData.previous=pwd;
testCase.TestData.out=tempname; mkdir(testCase.TestData.out); cd(testCase.TestData.out);
E=eeg_emptyset; E.nbchan=3; E.pnts=1000; E.trials=2; E.srate=250;
E.xmin=0; E.xmax=3.996; E.times=(0:999)*4;
t=(0:999)/250; E.data=repmat([sin(2*pi*10*t);sin(2*pi*15*t);sin(2*pi*20*t)],1,1,2);
E.data(:,:,2)=E.data(:,:,2)*2;
E.filename='synthetic.set'; E.filepath=testCase.TestData.out;
E.chanlocs=struct('labels',{'Cz','Pz','Fz'});
E.event=struct('type',{'stim','stim'},'latency',{51,1051},'epoch',{1,2});
testCase.TestData.EEG=E;
end

function teardownOnce(testCase)
cd(testCase.TestData.previous);
end

function testPluginLoadsOnce(testCase)
fig=figure('Visible','off'); cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
eegplugin_Neurolode(fig,struct,struct);
eegplugin_Neurolode(fig,struct,struct);
verifyNumElements(testCase,findobj(fig,'Tag','neurolode_menu'),1);
item=findobj(fig,'Label','AutoBatch');
verifyEqual(testCase,char(get(item,'Enable')),'on');
verifyTrue(testCase,contains(get(item,'Callback'),'[EEG, com] = pop_AutoBatch(EEG);'));
verifyTrue(testCase,contains(get(item,'Callback'),'LASTCOM = '''';'));
end

function testConversionPreservesEventsAndSamples(testCase)
EEG=testCase.TestData.EEG; expected=reshape(EEG.data,3,[]);
[converted,com]=convert2continuous(EEG);
verifyEqual(testCase,converted.data,expected);
verifyEqual(testCase,[converted.event.latency],[51 1051]);
verifyFalse(testCase,isfield(converted.event,'epoch'));
eval(com);
verifyEqual(testCase,EEG,converted);
end

function testAllExportModesAndFormats(testCase)
E=testCase.TestData.EEG;
for ga=0:1
 for ac=0:1
  expected=E.data;
  if ga, expected=mean(expected,3); end
  if ac, expected=mean(expected,1); end
  expected=reshape(expected,size(expected,1),[]);
  for ext={'.txt','.csv','.dat','.xlsx'}
   [~,file]=export2format(E,'1:3',ga,ac,0,ext{1},testCase.TestData.out);
   if strcmp(ext{1},'.dat')
    actual=readmatrix(file,'FileType','text','NumHeaderLines',1);
   else
    cells=readcell(file); actual=cell2mat(cells(2:end,2:end));
   end
   verifyEqual(testCase,actual,expected,'AbsTol',1e-7);
  end
 end
end
[~,file]=export2format(E,'1:1',1,1,0,'.csv');
cells=readcell(file); verifyEqual(testCase,cell2mat(cells(2,2:end)),mean(E.data(1,:,:),3),'AbsTol',1e-7);
end

function testAllSpectralCommandsAndHistory(testCase)
EEG=testCase.TestData.EEG;
metrics={'Centroid','Spread','Skewness','Kurtosis'};
domains={'Time','Freq','Custom'};
for m=1:4
 for d=1:3
  fn=['pop_EEG_Spectral_' metrics{m} '_' domains{d}];
  if d==1, tail={1}; elseif d==2, tail={512,256,1}; else, tail={512,256,[2 40],1}; end
  for avg=0:1
   [unchanged,com]=feval(fn,EEG,1:3,avg,1,tail{:});
   verifyEqual(testCase,unchanged.data,EEG.data);
   verifyNotEmpty(testCase,com); eval(com);
  end
  feval(fn,EEG,1,0,1,tail{:});
 end
end
files=dir('*Spectral*.xlsx'); verifyGreaterThanOrEqual(testCase,numel(files),24);
for k=1:numel(files)
 values=readcell(files(k).name);
 numeric=cell2mat(values(2:end,2:end));
 verifyTrue(testCase,all(isfinite(numeric),'all'),files(k).name);
end
end

function testSloretaWritesEpochs(testCase)
EEG=testCase.TestData.EEG;
[~,com]=pop_eeglab2sloreta(EEG,'sloreta',[],1);
verifyNotEmpty(testCase,com);
verifyNotEmpty(testCase,dir(fullfile('sloreta','**','*.asc')));
end
