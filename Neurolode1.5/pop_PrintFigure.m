
function pop_PrintFigure(EEG, gca)
%     sgtitle(EEG.setname(1:end-4));
%     set(gcf, 'PaperUnits', 'inches', 'PaperPosition', [0 0 3000 2000]/200);
%     t = datestr(now, 'mm_dd_yyyy_HHMM');
%     t = string(t);
%     t = string(t(1,1));
%     print(gcf, '-dpng', '-r200', strcat(EEG.setname(1:end-4),'_',t,'.jpg'));
%     close all
% end


userdata = get(get(gca,'Parent'),'userdata');

uilist0 = {{ 'Style', 'text', 'string', string(Ti), 'fontweight', 'bold'  }};
%uilist0 =  { 'Style', 'test', 'string', 'Channel','fontweight', 'bold' } 
uilist1 =  { 'Style', 'pushbutton', 'string', 'Channel spectra and maps',  'callback', ['LASTCOM = pop_spectopo(EEG, 1);'] } ;
uilist2 =  { 'Style', 'pushbutton', 'string', 'Channel properties',  'callback', ['LASTCOM = pop_prop(EEG,1);'] } ;
uilist3 =  { 'Style', 'pushbutton', 'string', 'Channel ERP image',  'callback', ['LASTCOM = pop_erpimage(EEG, 1)'] } ;
uilist4 =  { 'Style', 'pushbutton', 'string', 'Channel ERPs, With scalp maps',  'callback', ['LASTCOM = pop_timtopo(EEG);'] } ;
uilist5 =  { 'Style', 'pushbutton', 'string', 'Channel ERPs, In scalp/rect. array',  'callback', ['LASTCOM = pop_plottopo(EEG);'] };
uilist6 =  { 'Style', 'pushbutton', 'string', 'ERP map series, In 2-D',  'callback', ['LASTCOM = pop_topoplot(EEG, 1);'] } ;
uilist7 =  { 'Style', 'pushbutton', 'string', 'ERP map series, In 3-D',  'callback', ['[EEG LASTCOM] = pop_headplot(EEG, 1);'] } ;
uilist8 =  { 'Style', 'pushbutton', 'string', 'Sum/Compare ERPs',  'callback', ['LASTCOM = pop_comperp(ALLEEG);'] } ;
%uilist0 =  { 'Style', 'test', 'string', 'Component','fontweight', 'bold' } 
uilist9 =  { 'Style', 'pushbutton', 'string', 'Component spectra and maps',  'callback', ['LASTCOM = pop_spectopo(EEG, 0);'] } ;
uilist10 =  { 'Style', 'pushbutton', 'string', 'Component maps, 2-D',  'callback', ['LASTCOM = pop_topoplot(EEG, 0);'] } ;
uilist11 =  { 'Style', 'pushbutton', 'string', 'Component maps, 3-D',  'callback', ['[EEG LASTCOM] = pop_headplot(EEG, 0);'] } ;
uilist12 =  { 'Style', 'pushbutton', 'string', 'Component properties',  'callback', ['LASTCOM = pop_prop(EEG,0);'] } ;
uilist13 =  { 'Style', 'pushbutton', 'string', 'Component ERP image',  'callback', ['LASTCOM = pop_erpimage(EEG, 0);'] } ;
uilist14 =  { 'Style', 'pushbutton', 'string', 'Component ERPs, With component maps',  'callback', ['LASTCOM = pop_envtopo(EEG);'] } ;
uilist15 =  { 'Style', 'pushbutton', 'string', 'Component ERPs, Sum/Compare comp. ERPs ',  'callback', ['LASTCOM = pop_comperp(ALLEEG, 0);'] };


uilist16   = {{ 'Style', 'text', 'string', 'OR, add a generic save figure function that will save each file with filename', 'fontweight', 'bold'  }};
uilist18   = {{ 'Style', 'text', 'string', 'This option is good if you have a figure function already in the AutoBatchGUI', 'fontweight', 'bold'  }};
uilist19   = {{ 'Style', 'checkbox', 'string', 'Add genetric Figure save', 'value', 0, 'fontweight', 'bold'}};

uilist0s = [uilist0 uilist1 uilist2 uilist3 uilist4 uilist5 uilist6 uilist7 uilist8 uilist9 uilist10 uilist11 uilist12 uilist13 uilist14 uilist15 uilist16 uilist17 uilist18 uilist19];
geometry = {  [1]     [1]     [1]     [1]     [1]     [1]     [1]     [1]     [1]     [1]     [1]       [1]     [1]       [1]     [1]       [1]     [1]       [1]     [1]      [1]};
userdata = userdata;
userdata.CurrOper = CurrOper;
[results userdata returnmode] = inputgui('geometry', geometry, 'uilist', uilist0s, 'helpcom','pophelp(''pop_chanedit'');', 'title', Ti, 'userdata', userdata);

if results{1,2} == 1
    OriOper = userdata.CurrOper;
    NewOper = results{1,1};
    userdata = get(get(gca,'Parent'),'userdata');
    [idxC, ~] = find(contains(string(userdata.Operation),OriOper));
    userdata.Operation{idxC,1} = NewOper;
    set(get(gca,'Parent'), 'userdata', userdata);
end










