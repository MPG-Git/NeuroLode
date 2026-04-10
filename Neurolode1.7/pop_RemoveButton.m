% pop_RemoveButton(gca,gco) - This function Removes unwanted scripts form GUI to makes a batch able script. 
%
% Usage:
%   >>  pop_RemoveButton(gca,gco);
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

function pop_RemoveButton(gca,gco)
    if nargin < 2 || isempty(gca) || isempty(gco) || ~ishandle(gca) || ~ishandle(gco)
        warning('AutoBatch:RemoveButtonInvalidHandle', 'Invalid GUI handles. Remove ignored.');
        return;
    end
    TagName = get(gco,'tag');
    userdata = get(get(gca,'Parent'),'userdata');
    if ~isstruct(userdata) || ~isfield(userdata,'OrderName') || ~isfield(userdata,'OrderNum') || isempty(userdata.OrderName)
        warning('AutoBatch:RemoveButtonMissingState', 'AutoBatch state missing. Remove ignored.');
        return;
    end
    NewOrderName = userdata.OrderName;
    NewOrderNum = userdata.OrderNum;
    MapPOS = zeros(size(NewOrderName,1),4);    
    if userdata.UpDownButtonRun == 0
        for i=1:size(NewOrderName,1)
            h = findobj('Tag',NewOrderName{i,1});
            if isempty(h), continue; end
            MapPOS(i,1:end) = h(1,1:end).Position;
        end
    else
        if ~isfield(userdata,'POS') || isempty(userdata.POS)
            warning('AutoBatch:RemoveButtonMissingPositions', 'Position map missing. Remove ignored.');
            return;
        end
        MapPOS = userdata.POS;
    end    
    idx = userdata.OrderNum(strcmp(vertcat(userdata.OrderName{:}),TagName),1);
    if isempty(idx)
        warning('AutoBatch:RemoveButtonTagNotFound', 'Button tag not found in order list. Remove ignored.');
        return;
    end
    Ori = find(vertcat(userdata.OrderNum{:}) == idx{:});
    if isempty(Ori), return; end
    OriO = vertcat(userdata.OrderNum{:});
    
    OriRem = vertcat(NewOrderName(Ori,:));
    for i=1:size(Ori,1)
        h = findobj('tag', OriRem{i,1});
        if ~isempty(h), delete(h); end
    end
   
     for i=Ori(1,1):size(OriO,1)
         OriO(i,1) = OriO(i,1)-1;
     end   
%      OriO = OriO(any(OriO,2),:);
    NewOrderNum = num2cell(OriO);     
    NewOrderName(Ori,:) = [];
    NewOrderNum(Ori,:) = [];
    MapPOS((1+end)-size(Ori,1):end,:) = [];
    
    %userdata.Operation = string(userdata.Operation{:});
    if isfield(userdata,'Operation') && numel(userdata.Operation) >= idx{:}
        userdata.Operation(idx{:},:) = [];
    end
    
    for i=1:size(MapPOS,1)
        h = findobj('tag', NewOrderName{i,1});
        if isempty(h), continue; end
        set(h,'position', MapPOS(i,:));
    end    
    userdata.OrderName = NewOrderName;    
    userdata.OrderNum = NewOrderNum;
    userdata.UpDownButtonRun = 1;
    userdata.POS = MapPOS;
    userdata.Operation = userdata.Operation;
    set(get(gca,'Parent'), 'userdata', userdata);
    
