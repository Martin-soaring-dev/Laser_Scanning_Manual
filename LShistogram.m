function obj = LShistogram(obj)   
%%  依赖关系判断
if obj.syset.flags.read_flag_af~=1
    error('tilt correction has not been processed yet!')
end
%%  处理
% h = histogram(obj.PC_data_merged.fitted_PC.X(:,3),10);
h = histogram(obj.PC_data_merged.fitted_PC.X(:,3));
set(gca,'FontName','Times New Roman')
%   保存绘图句柄
obj.LS_plot.histogram = fullfile(obj.syset.path_plotmp,'histogram.mat');
save(obj.LS_plot.histogram, 'h');
%%  结束与标记
obj.syset.flags.read_flag_histog = 1;
end
% % tt = find(obj.PC_data_merged.fitted_PC.X(:,3)>-8);
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
% hold off
% view([1 0 0])
% view([0 0 1])
% tt = find(obj.PC_data_merged.fitted_PC.X(:,3)>h.BinEdges(find(aaa==min(aaa))+6));
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
% hold off
% [idx corepts]=dbscan(obj.PC_data_merged.fitted_PC.X(tt,1:3),1,50);
% numGroups = length(unique(idx));
% gscatter(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),idx,hsv(numGroups));
% % scatter3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),5,idx,'filled')
% legend()
% view([0 0 1])
% view([1 0 0])