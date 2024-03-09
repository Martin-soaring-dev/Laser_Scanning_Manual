function obj = LS_surface_fitting(obj,plot_flag)
%%  依赖关系判断
if obj.syset.flags.read_flag_af~=1
    error('tilt correction has not been processed yet!')
end
%%  拟合
if ~exist("plot_flag")
    plot_flag=0;
end
fit_mode = 1;
seg = 0.02;          %使用时fit mode = 1;拟合精度mm
num = 1000;         %使用时fit mode = 2;拟合精度网格数量
temp = [obj.PC_data_merged.fitted_PC.X];
x_profile = temp(:,1);
y_profile = temp(:,2);
z_profile = temp(:,3);
clear temp
%   剔除无效点
snxyz = ~isnan(x_profile) & ~isnan(y_profile) & ~isnan(z_profile);
F = scatteredInterpolant(x_profile(snxyz), y_profile(snxyz), z_profile(snxyz), 'natural', 'none');
%   保存函数
obj.Surface.surface_eq = F;
%   绘图
points = [x_profile(snxyz), y_profile(snxyz), z_profile(snxyz)];
[X,Y] = meshgrid(min(points(:,1)):0.1:max(points(:,1)), min(points(:,2)):0.1:max(points(:,2)));
Z = F(X,Y);
h = figure('Name','surface_fitting','NumberTitle','off');
surf(X,Y,Z,'EdgeColor','none');
% obj.Surface.plot = mesh(X,Y,Z);
% hold on
% plot3(points(:,1),points(:,2),points(:,3),'r.')
% hold off
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Fitted Surface');
set(gca,'FontName','Times New Roman')
%   保存绘图句柄
obj.LS_plot.surface_fitting = fullfile(obj.syset.path_plotmp,'surface_fitting.mat');
save(obj.LS_plot.surface_fitting, 'h');
if ~plot_flag
    close(h)
end
%%  结束与标记
obj.syset.flags.read_flag_sf = 1;
end