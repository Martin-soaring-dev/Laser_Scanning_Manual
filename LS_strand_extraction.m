function obj = LS_strand_extraction(obj)
%%  依赖关系判断
if obj.syset.flags.read_flag_histog~=1
    error('histog has not been processed yet!')
end
%%  处理程序
%   读取直方图句柄
load(obj.LS_plot.histogram,'h');
data = h.Data;
valu = h.Values;
edge = h.BinEdges;
widt = h.BinWidth;
d_valu=valu(2:end)-valu(1:end-1);
pedg = find(d_valu<=-std(d_valu),1,'last');
zreg = edge(pedg);
% 观察直方图，发现直方图的峰值代表了平面，因此峰值右侧就是线条区域
% 因此这里求直方图差分，并找到差分均方差对应的高度zreg，作为参考，查找大于这个值的点，就可以提取线条了
% 效果比较好
tn = obj.PC_data_merged.fitted_PC.X(:,3)>zreg;  
tn = reshape(tn,[],1);
obj.PC_data_merged.group_data.act = tn-~tn; %只有1和-1
obj.PC_data_merged.group_data.reg = zreg;   %保存参考
temp = obj.PC_data_merged.fitted_PC.X;      
%缓存...2024-01-30 Martin
%这个地方只能这样，如果直接赋值，会炸（PC_data_merged下的pointCloud类都会被修改），查了一天...
obj.PC_data_merged.group_data.Z = temp(:,3);
tt = find(tn);                              %找到tn中等于1的，防止绘图的时候报错
% nt = obj.PC_data_merged.fitted_PC.X(:,3)>zreg;
% nt = ~nt;

%   绘图
figure(1)
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
h = scatter3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.group_data.Z(tt),10,obj.PC_data_merged.group_data.Z(tt),'filled');
% hold off
title('Stand Extraction')
% legend('original','extracted','Location','northeast')
legend('Location','northeast')
set(gca,'FontName','Times New Roman')
% view([1 0 0])
view([0 0 1])

%   保存绘图句柄
obj.LS_plot.strand_extraction = fullfile(obj.syset.path_plotmp,'strand_extraction.mat');
save(obj.LS_plot.strand_extraction, 'h');
%%  结束与标记
obj.syset.flags.read_flag_sdextr = 1;
end
%   分组
% epsilon = 1;
% minpts  = 700;  %   this may adjust to improve result
% [idx corepts]=dbscan(obj.PC_data_merged.fitted_PC.X(tt,1:3),1,700);
% numGroups = length(unique(idx));
% figure(2)
% gscatter(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),idx,hsv(numGroups));
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
