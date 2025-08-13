% pop_SaveNopen(gca,gco) - This create a batchable script from the GUI of pop_AutoBatch
%
% Usage:
%   >>  pop_SaveNopen(gca,gco);
%
% Inputs:
%   gca     - Current axes or chart.
%   gco  - Current axes or chart object.
%    
% Author: Matthew Phillip Gunn 
%
% See also: 
%   eeglab , inputgui , supergui, pop_MoveButton, pop_RemoveButton, pop_SaveNopen

% Copyright (C) 2022  Matthew Gunn, Southern Illinois University Carbondale, matthewpgunn@gmail.com
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function pop_SaveNopen(gca,gco)    
userdata = get(get(gca,'Parent'),'userdata');
AA = get(gca,'Parent');
AD = get(AA,'userdata');

ScriptPre = {};
ScriptPre{end+1,1} = 'clc';
ScriptPre{end+1,1} = 'clear';
ScriptPre{end+1,1} = 'path0 = pwd;';
ScriptPre{end+1,1} = 'path1 = strcat(path0,''\0_Pre\'');';
ScriptPre{end+1,1} = 'path2 = strcat(path0,''\0_Post\'');';
ScriptPre{end+1,1} = 'cd(path1);';
ScriptPre{end+1,1} = 'file1 = dir(''*.set'');';
ScriptPre{end+1,1} = 'for i=1:size(file1,1)';
ScriptPre{end+1,1} = 'EEG =  pop_loadset(file1(i).name, path1,''all'',''all'',''all'',''all'',''auto'');';

ScriptPost = {};
ScriptPost{end+1,1} = 'EEG= pop_saveset(EEG, ''filename'', [file1(i).name(1:end-4), ''Post.set''], ''filepath'',path2);';
ScriptPost{end+1,1} = 'end';

NewScr = vertcat(ScriptPre,userdata.Operation,ScriptPost);
t = datestr(now, 'mm_dd_yyyy_HHMM');
t = string(t);
t = t(1,1);
temp =  strcat(pwd,'\AutoBatchScript_',t);
mkdir(temp);
cd(temp);
mkdir('0_Pre');
mkdir('0_Post');
fileID  = fopen(strcat(pwd,'\AutoBatchScript_',t,'.m'), 'w+');
for i=1:size(NewScr,1)
    fprintf(fileID,'%s\n',NewScr{i,1});
    if i == (size(NewScr,1)-1)
        fprintf(fileID,'%s\n','close all %Added to close opens, will be removed in future releases when solution found');
    end
end
fclose(fileID);
userdata.NewScr = strcat(pwd,'\AutoBatchScript_',t,'.m');
set(get(gca,'Parent'), 'userdata', userdata);
AA = get(gca,'Parent');
AD = get(AA,'userdata');
close;
edit(AD.NewScr);
    