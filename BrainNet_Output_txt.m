function output_txt = BrainNet_Output_txt(obj,event_obj)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

pos = get(event_obj,'Position');
output_txt = {['X: ',num2str(pos(1),4)],...
    ['Y: ',num2str(pos(2),4)]};

% If there is a Z-coordinate in the position, display it as well
if length(pos) > 2
    output_txt{end+1} = ['Z: ',num2str(pos(3),4)];
end

%% Added by Mingrui Xia, 20120806 show value of selected vertex
global FLAG
global surf
global EC
if FLAG.Loadfile > 8 && EC.vol.type == 1
    coordmat = repmat(pos',[1,size(surf.coord,2)]);
    dif = sum(surf.coord - coordmat);
    output_txt{end+1} = ['Val: ',num2str(surf.T(dif==0))];
end

%% show AAL and Brodmann Area name
global OutputText
if ~isempty(OutputText.AAL)
    sub = round(OutputText.AAL.AAL_hdr.mat \ [pos,1]');
    ind = OutputText.AAL.AAL_vol(sub(1),sub(2),sub(3));
    if ind ~= 0
        output_txt{end+1} = OutputText.AAL.AAL_label{ind};
    end
end
if ~isempty(OutputText.Brodmann)
    sub = round(OutputText.Brodmann.Brodmann_hdr.mat \ [pos,1]');
    ind = OutputText.Brodmann.Brodmann_vol(sub(1),sub(2),sub(3));
    if ind ~= 0
        output_txt{end+1} = ['Brodmann Area',num2str(ind)];
    end
end

%% show Cluster area, add by Mingrui 20140415
% if FLAG.Loadfile > 8 && EC.vol.type == 1
%     coordmat = repmat(pos',[1,size(surf.coord,2)]);
%     dif = sum(surf.coord - coordmat);
%     ind = find(dif == 0);
%     if surf.T(ind) ~= 0
%         if surf.T(ind)~= fix(surf.T(ind))
%             e = 0;
%             oldneibour = [];
%             l = [];
%             while e == 0
%                 for i = 1:length(ind)
%                     [m,n] = find(surf.tri == ind(i));
%                     l = unique([l;m]);
%                 end
%                 ind = unique(surf.tri(l,:));
%                 if length(ind) == length(surf.T)
%                     e = 1;
%                 else
%                     v = (surf.T(ind));
%                     ind(v == 0) = [];
%                     if isequal(ind,oldneibour)
%                         e = 1;
%                     else
%                         oldneibour = ind;
%                     end
%                 end
%             end
%             mval = mean(surf.T(ind));
%             output_txt{end+1} = ['Mean: ',num2str(mval)];
%             ind = unique(l);
%             f = surf.tri(ind,:);
%             f = surf.T(f);
%             f = f(:,1).*f(:,2).*f(:,3);
%             ind(f == 0) = [];
%             x = surf.coord(1:3,surf.tri(ind,1));
%             y = surf.coord(1:3,surf.tri(ind,2));
%             z = surf.coord(1:3,surf.tri(ind,3));
%             c = cross(x' - y', x' - z',2);
%             area = sum(1/2.*sqrt(sum(c.*c,2)));
%             
%             output_txt{end+1} = ['Area: ',num2str(area), ' mm2'];
%         else
%             ind = find(surf.T == surf.T(ind));
%             l = [];
%             for i = 1:length(ind)
%                 [m,n] = find(surf.tri == ind(i));
%                 l = unique([l;m]);
%             end
%             ind = l;
%             x = surf.coord(1:3,surf.tri(ind,1));
%             y = surf.coord(1:3,surf.tri(ind,2));
%             z = surf.coord(1:3,surf.tri(ind,3));
%             c = cross(x' - y', x' - z',2);
%             area = sum(1/2.*sqrt(sum(c.*c,2)));
%             output_txt{end+1} = ['Area: ',num2str(area), ' mm2'];
%         end
%     end
% end