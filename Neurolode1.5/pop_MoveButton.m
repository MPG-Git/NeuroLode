% pop_MoveButton(gca,gco) - This function Moves button for GUI to makes a batch able script. 
%
% Usage:
%   >>  pop_MoveButton(gca,gco);
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

function pop_MoveButton(gca,gco)
    TagName = get(gco,'tag');    
    userdata = get(get(gca,'Parent'),'userdata');
    NewOrderName = userdata.OrderName;
    NewOrderNum = userdata.OrderNum;
    MapPOS = zeros(size(NewOrderName,1),4);    
    if userdata.UpDownButtonRun == 0
        for i=1:size(NewOrderName,1)
            h = findobj('Tag',NewOrderName{i,1});
            MapPOS(i,1:end) = h(1,1:end).Position;
        end
    else
        MapPOS = userdata.POS;
    end    
    idx = userdata.OrderNum(strcmp(vertcat(userdata.OrderName{:}),TagName),1);   
    if contains(TagName,'UpB')
        Move2Target = idx{:} - 1; %is it at top alrdy?
    elseif contains(TagName,'Dow')
        Move2Target = idx{:} + 1; %is it at bottom alrdy?
    end
    if Move2Target > 0 && Move2Target < NewOrderNum{end,1}+1
        Ori = find(vertcat(userdata.OrderNum{:}) == idx{:});
        New = find(vertcat(userdata.OrderNum{:}) == Move2Target);
        for i=1: size(Ori,1)
            NewOrderName(New(i,1),1) =  userdata.OrderName(Ori(i,1),1);
            NewOrderName(Ori(i,1),1) =  userdata.OrderName(New(i,1),1);
        end
    end
    for i=1:size(MapPOS,1)
        set(findobj('tag', NewOrderName{i,1}),'position', MapPOS(i,:));
    end    
    userdata.OrderName = NewOrderName;    
    userdata.OrderNum = userdata.OrderNum;
    userdata.UpDownButtonRun = 1;
    userdata.POS = MapPOS;
    userdata.Operation = userdata.Operation;
    set(get(gca,'Parent'), 'userdata', userdata);
    