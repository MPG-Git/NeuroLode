% pop_functionsettings(gca,gco) - This displays the function of button for create a batchable
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
function pop_functionsettings(gca,gco)

userdata = get(get(gca,'Parent'),'userdata');
AC = get(gco,'tag');
[idxC, ~] = find(contains(string(userdata.OrderName),AC));
CurrOper = userdata.Operation(userdata.OrderNum{idxC,1},1);
k0 = strfind(CurrOper,'=');
k1 = strfind(CurrOper,'(');
if ~isempty(k0) && ~isempty(k1)
    temp = CurrOper{1,1};
    ProcessHolder = temp(1,k0{:}+2:k1{:}-1);
    OperVars = temp(1,k1{:}+1:end-3);
end
OperVars = cellfun(@(x)regexp(x,',','split'),string(OperVars),'UniformOutput',0);
OperVars = OperVars{:};
VarListName = {};
VarListInput  = {};
VarIdx = 1;
while VarIdx <= size(OperVars,2)
    k0 = strfind(OperVars{1,VarIdx},'''');
    if k0 > 0
        VarListName{end+1,1}  = OperVars{1,VarIdx};
        VarListInput{end+1,1} = OperVars{1,VarIdx+1};
        VarIdx = VarIdx + 2;
    else
        VarIdx = VarIdx + 1;
    end
end
UIL = ceil(sqrt(size(VarListName,1)));
UIL = ones(1,2);
Ti = sprintf(strcat('AutoBatch Function Setting For:', 32,ProcessHolder));
geometry = {};
for i=1:size(VarListName,1)
    geometry{1,end+1} =  UIL;
end
uilist = {};
for i=1:size(VarListName,1)
    uilist00 =   {{ 'Style', 'text', 'string', (VarListName{i,1}) 'fontweight', 'bold' },{ 'Style', 'text', 'string', (VarListInput{i,1}) }};
    uilist = [uilist uilist00];
end
uilist0   = {{ 'Style', 'text', 'string', string(Ti), 'fontweight', 'bold'  }};

uilist1   = {{ 'Style', 'text', 'string', '', 'fontweight', 'bold'  }};
uilist2   = {{ 'Style', 'text', 'string', 'Uneditted', 'fontweight', 'bold'  }};
uilist3   = {{ 'Style', 'text', 'string', string(CurrOper) }};
uilist4   = {{ 'Style', 'text', 'string', 'Editable', 'fontweight', 'bold'  }};
uilist5   = {{ 'Style', 'edit', 'string', string(CurrOper) }};
%uilist6   = {{'Style', 'pushbutton', 'string', 'Save changes', 'callback', [strcat('pop_editAB(',string(CurrOper),')')]}};
  uilist6   = {{'Style', 'checkbox', 'string', 'Save changes', 'value', 0, 'fontweight', 'bold'}};
      
uilist0 = [uilist0 uilist uilist1 uilist2 uilist3 uilist4 uilist5 uilist6];
geometry   = {[1] geometry{:} [1] [1] [1] [1] [1] [1]};
userdata = userdata;
userdata.CurrOper = CurrOper;
[results userdata returnmode] = inputgui('geometry', geometry, 'uilist', uilist0, 'helpcom','pophelp(''pop_chanedit'');', 'title', Ti, 'userdata', userdata);
try
    if results{1,2} == 1
        OriOper = userdata.CurrOper;
        NewOper = results{1,1};
        userdata = get(get(gca,'Parent'),'userdata');
        [idxC, ~] = find(contains(string(userdata.Operation),OriOper));
        userdata.Operation{idxC,1} = NewOper;
        set(get(gca,'Parent'), 'userdata', userdata);
    end
catch
end

