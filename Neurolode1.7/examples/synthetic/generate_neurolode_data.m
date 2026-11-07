function generate_neurolode_data(destination)
if nargin<1, destination=fullfile(fileparts(mfilename('fullpath')),'data'); end
assert(~isfolder(destination),'Choose a new destination'); mkdir(destination);
E=eeg_emptyset; E.nbchan=3; E.pnts=1000; E.trials=2; E.srate=250;
E.xmin=0; E.xmax=3.996; E.times=(0:999)*4;
t=(0:999)/250;
E.data=repmat([sin(2*pi*10*t);sin(2*pi*15*t);sin(2*pi*20*t)],1,1,2);
E.data(:,:,2)=2*E.data(:,:,1); E.chanlocs=struct('labels',{'Cz','Pz','Fz'});
E.event=struct('type',{'stim','stim'},'latency',{51,1051},'epoch',{1,2},'duration',{0,0});
E.setname='Synthetic 10, 15, 20 Hz'; E.subject='synthetic';
E.comments='Generated sinusoids in microvolts. Epoch 2 has twice the amplitude of epoch 1.';
E=eeg_checkset(E,'eventconsistency');
pop_saveset(E,'filename','synthetic.set','filepath',destination,'savemode','onefile');
demo_portable_set(fullfile(destination,'synthetic.set'));
end
