function obj = LS_strand_grouping(obj,epsilon,minpts)
%%  依赖关系判断
if obj.syset.flags.read_flag_sdextr~=1
    error('strand extractin has not been processed yet!')
end
%%  处理程序
%   分组
% epsilon = 1;
% minpts  = 700;  %   this may adjust to improve result
tt = find(obj.PC_data_merged.group_data.act>0); % 提取时初选的点中大于零的位置
tn = obj.PC_data_merged.group_data.act;         % 提取时初选的点有效情况
[idx corepts]=dbscan(obj.PC_data_merged.fitted_PC.X(tt,1:3),epsilon,minpts);%分组
typGroups = unique(idx);                        % 有多少组
numGroups = length(typGroups);                  % 组数
for i=1:numGroups
    tn(tt(find(idx==typGroups(i))))=typGroups(i); %把初选点中需要修改的修改了
end
% disp([obj.PC_data_merged.group_flag,tn])
obj.PC_data_merged.group_data.act = tn;         % 分组信息保存 -1(噪点) 分组：1 2 3 ...
% temp = obj.PC_data_merged.fitted_PC.X;
% obj.PC_data_merged.group_data.Z(tn<0,3)=min(temp(:,3)); %

%   绘图
figure(2)
h = gscatter(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),idx,hsv(numGroups));
title([num2str(epsilon),', ',num2str(minpts)])
% obj.PC_data_merged.fitted_PC.plot

%   保存绘图句柄
obj.LS_plot.strand_grouping = fullfile(obj.syset.path_plotmp,'strand_grouping.mat');
save(obj.LS_plot.strand_grouping, 'h');
%%  结束与标记
obj.syset.flags.read_flag_sdgrou = 1;
end
% scatter3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),5,idx,'filled')

% tt = find(obj.PC_data_merged.fitted_PC.X(:,3)>h.BinEdges(find(aaa==min(aaa))+6));
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
% hold off
% [idx corepts]=dbscan(obj.PC_data_merged.fitted_PC.X(tt,1:3),1,50);
% numGroups = length(unique(idx));
% gscatter(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),idx,hsv(numGroups));
% scatter3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),5,idx,'filled')